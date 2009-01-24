$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'parse_tree'
require 'sexp_processor'
require 'sexp'

module RewriteRails
  
  # Adds a guarded method invocation to Ruby:
  #
  #     @phone = Location.find(:first, ...elided... ).andand.phone
  #
  # It also works with parameters, blocks, and procs passed as blocks.
  #
  # Works by rewriting expressions like:
  #
  #   numbers.andand.inject(&:+)
  #
  # Into:
  #
  #  begin
  #    __12345__ = numbers
  #    __12345__ && __12345__.inject(&:+)
  #  end
  #
  class Andand < SexpProcessor

=begin
s(:iter,
 s(:call, s(:lvar, :foo), :inject),
 s(:masgn, s(:array, s(:dasgn_curr, :a), s(:dasgn_curr, :b)), nil, nil),
 s(:call, s(:lvar, :a), :+, s(:array, s(:lvar, :b))))
=end
    def process_iter(exp)
      exp.shift
      sub_expression = exp.first #[:call, [:call, [:lit, 1..10], :andand], :inject]
      # or: [:call, [:lit, :foo], :andand, [:arglist]]
      if sub_expression[0] == :call && matches_andand_invocation(sub_expression[1])
        exp.shift
        receiver_expr = process_inner_expr(sub_expression[1][1])
        if truthy?(receiver_expr)
          begin
            return s(:iter, 
              s(:call, 
                receiver_expr, 
                *(sub_expression[2..-1].map { |inner| process_inner_expr(inner) })
              ), 
              *(exp.map { |inner| process_inner_expr(inner) })
            )
          ensure
            exp.clear
          end
        elsif falsy?(receiver_expr)
          begin
            return receiver_expr
          ensure
            exp.clear
          end
        elsif (receiver_expr.first == :lvar)
          lhs_and = receiver_expr.dup
          new_receiver = receiver_expr.dup
        else
          mono_parameter = Rewrite.gensym()
          lhs_and = s(:lasgn, mono_parameter, receiver_expr)
          new_receiver = s(:lvar, mono_parameter)
        end
        s(:and, 
          lhs_and,
          begin
            s(:iter, 
              s(:call, 
                new_receiver, 
                *(sub_expression[2..-1].map { |inner| process_inner_expr(inner) })
              ), 
              *(exp.map { |inner| process_inner_expr(inner) })
            )
          ensure
            exp.clear
          end
        )
      elsif matches_andand_block_invocation(sub_expression) # [:call, [:lit, :foo], :andand, [:arglist]]
        target_sexp = process_inner_expr(sub_expression[1])
        exp.shift
        potential_assignment = exp.shift
        param_sym = if potential_assignment.respond_to?(:first) && potential_assignment.first == :lasgn
          potential_assignment.last
        end
        remainder = exp.shift and s(:and,
          (param_sym ? s(:lasgn, param_sym, target_sexp) : target_sexp),
          if remainder.respond_to?(:first) && remainder.first == :block
            s(:block, *(remainder[1..-1].map { |inner| process_inner_expr(inner) }))
          else
            process_inner_expr(remainder)
          end
        ) or target_sexp
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
    
=begin
  [:and, 
    [s(:lasgn, :__TEMP__, s(:call, nil, :foo, s(:arglist))), s(:lvar, :__TEMP__)], 
    [:call, [:lvar, :__TEMP__], :bar, [:arglist]]
  ]
=end
    def process_call(exp)
      # s(:call, s(:call, s(:lit, :foo), :andand), :bar)
      exp.shift
      # s(s(:call, s(:lit, :foo), :andand), :bar)
      sub_expression = exp.first
      if matches_andand_invocation(sub_expression) # s(:call, s(:lit, :foo), :andand)
        exp.shift
        # s( :bar )
        receiver_expr = process_inner_expr(sub_expression[1])
        if truthy?(receiver_expr)
          begin
            return s(:call, 
              receiver_expr,
              *(exp.map { |inner| process_inner_expr(inner) }))
          ensure
            exp.clear
          end
        elsif falsy?(receiver_expr)
          begin
            return receiver_expr
          ensure
            exp.clear
          end
        elsif (receiver_expr.first == :lvar)
          lhs_and = receiver_expr
          new_receiver = receiver_expr
        else
          mono_parameter = Rewrite.gensym()
          lhs_and = s(:lasgn, mono_parameter, receiver_expr)
          new_receiver = s(:lvar, mono_parameter)
        end
        s(:and, 
          lhs_and,
          begin
            s(:call, 
              new_receiver,
              *(exp.map { |inner| process_inner_expr(inner) }))
          ensure
            exp.clear
          end
        )
      else
        # pass through
        begin
          s(:call,
            *(exp.map { |inner| process_inner_expr(inner) })
          )
        ensure
          exp.clear
        end
      end
    end
    
    private 
    
    def truthy?(sexp)
      sexp.respond_to?(:[]) && (sexp[0] == :true || sexp[0] == :lit || sexp[0] == :str || sexp[0] == :array)
    end
    
    def falsy?(sexp)
      sexp.respond_to?(:[]) && (sexp[0] == :nil || sexp[0] == :false)
    end
    
    def process_inner_expr(inner)
        inner.kind_of?(Array) ? process(inner) : inner
    end
    
    def matches_andand_invocation(sexp)
      sexp.respond_to?(:[]) && sexp[0] == :call && sexp[2] == :andand
    end
    
    def matches_andand_block_invocation(sexp)
      matches_andand_invocation(sexp) && sexp.last.to_a == [:arglist]
    end
    
  end

end