$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'parse_tree'
require 'sexp_processor'

module RewriteRails
  
  # Takes a sexp representing a block and rewrites all of its parameter references as thunk calls.
  #
  # Example:
  #
  #   foo { |a,b| a + b }
  #     => foo { |a,b| a.call + b.call }
  #
  class RewriteParametersAsThunkCalls
  
    def sexp(exp)
      if exp.kind_of? Array
        s(*exp.map { |e| sexp(e) })
      else
        exp
      end
    end
  
    #s(:iter, s(:call, nil, :proc, s(:arglist)), s(:lasgn, :foo), s(:lit, :foo))
    def process(sexp)
      variable_symbols = RewriteRails.arguments(sexp)
      returning(eval(sexp.inspect)) do |new_sexp|
        new_sexp[3] = variable_symbols.inject(sexp[3]) { |result, variable|
          VariableRewriter.new(variable, s(:call, s(:lvar, variable), :call, s(:arglist))).process(eval(result.inspect))
        }
      end
    end
  
  end
  
end