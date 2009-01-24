$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'parse_tree'
require 'sexp_processor'
require 'sexp'

module RewriteRails
  
  #--
  #
  # TODO: Implement splat variables somehow
  #
  # def test_splat_variables
  #   
  #   assert_equal(
  #     lambda { |*a| a[0].call }.to_sexp.to_a,
  #     RewriteRails::RewriteVariablesAsThunkCalls.new(:a).process(
  #       lambda { |*a| a[0] }.to_sexp
  #     ).to_a
  #   )
  #   
  # end
  
  class VariableRewriter < SexpProcessor
    
    attr_reader :replacement_sexp
    
    def initialize symbol, replacement_sexp
      @symbol, @replacement_sexp = symbol, replacement_sexp
      super()
    end
    
    #missing: rewriting assignment. Hmmm.
    
    def subprocess (something)
      process(something) if something
    end

    def process_lvar(exp)
      exp.shift
      variable = exp.shift
      if @symbol == variable
        replacement_sexp # not a deep copy. problem? replace with a block call??
      else
        s(:lvar, variable)
      end
    end
    
    def process_lvar(exp)
      exp.shift
      variable = exp.shift
      if @symbol == variable
        replacement_sexp # not a deep copy. problem? replace with a block call??
      else
        s(:lvar, variable)
      end
    end
    
    def process_iter(exp) # don't handle subtrees where we redefine the variable, including lambda and proc
      original = exp.to_a.dup
      exp.shift
      callee_expr = exp.shift # we process in our context
      params_exp = exp.shift
      block_body = exp.shift
      params = if params_exp.nil?
        []
      elsif params_exp.first == :dasgn || params_exp.first == :dasgn_curr
        [ params_exp[1] ]
      elsif params_exp.first == :lasgn || params_exp.first == :lasgn_curr
        [ params_exp[1] ]
      elsif params_exp.first == :masgn
        raise "Can't handle  #{original.inspect}" unless params_exp[1].first == :array
        params_exp[1][1..-1].map { |assignment| assignment[1] }
      else
        raise "Can't handle #{original.inspect}, expected #{params_exp} to resemeble [:dasgn, ...] or [:masgn, ...]"
      end
      if params.include? @symbol
        s(:iter, subprocess(callee_expr), params_exp, block_body) # we're DONE
      else
        s(:iter, subprocess(callee_expr), params_exp, subprocess(block_body)) # we're still in play
      end
    end
    
  end
  
end