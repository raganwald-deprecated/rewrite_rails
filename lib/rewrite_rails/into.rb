$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'parse_tree'
require 'sexp_processor'
require 'sexp'

module RewriteRails

  # class Object
  #   def into
  #     yield(self)
  #   end
  # end
  class Into < SexpProcessor

=begin
  [:iter,
    [:call, [:lit, :foo], :into, [:arglist]], 
    [:lasgn, :foo], 
    [:lvar, :foo]
  ]
=end
    def process_iter(exp)
      exp.shift
      sub_expression = exp.first # [:call, [:lit, :foo], :into, [:arglist]]
      if matches_into_block_invocation(sub_expression) # [:call, [:lit, :foo], :into, [:arglist]]
        target_sexp = process_inner_expr(sub_expression[1])
        exp.shift
        potential_assignment = exp.shift
        remainder = exp.shift
        if remainder
          if potential_assignment.respond_to?(:first) && potential_assignment.first == :lasgn
            # expression.into { |param_sym| ... }
            param_sym = potential_assignment.last
            if remainder.respond_to?(:first) && remainder.first == :block
              # expression.into { |param_sym| ...; ... }
              s(:block, 
                s(:lasgn, param_sym, target_sexp),
                *(remainder[1..-1].map { |inner| process_inner_expr(inner) })
              )
            else
              # expression.into { |param_sym| ... }
              s(:block, 
                s(:lasgn, param_sym, target_sexp),
                process_inner_expr(remainder)
              )
            end
          else
            # expression.into { ... }
            if remainder.respond_to?(:first) && remainder.first == :block
              # expression.into { ...; ... }
              s(:block, 
                target_sexp,
                *(remainder[1..-1].map { |inner| process_inner_expr(inner) })
              )
            else
              # expression.into { ... }
              s(:block, 
                target_sexp,
                process_inner_expr(remainder)
              )
            end
          end
        else
          # expression into { }
          target_sexp
        end
      else
        begin
          s(:iter,
            *(exp.map { |inner| process_inner_expr(inner) })
          )
        ensure
          exp.clear
        end
      end
    end
    
    private 
    
    def process_inner_expr(inner)
        inner.kind_of?(Array) ? process(inner) : inner
    end
    
    def matches_into_block_invocation(sexp)
      sexp.respond_to?(:[]) && sexp[0] == :call && sexp[2] == :into && sexp.last.to_a == [:arglist]
    end
    
  end

end