$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'parse_tree'
require 'sexp_processor'
require 'sexp'

module RewriteRails
  
  class RewriteVariablesAsThunkCalls
    
    attr_reader :list_of_variables
    
    def initialize(*list_of_variables)
      @list_of_variables = list_of_variables
    end
    
    def process(sexp)
      list_of_variables().inject(sexp) { |result, variable| 
        VariableRewriter.new(variable, s(:call, s(:lvar, variable), :call, s(:arglist))).process(result)
      }
    end
    
  end
  
end