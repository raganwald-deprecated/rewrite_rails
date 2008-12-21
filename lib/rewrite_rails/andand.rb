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
 s(:call, s(:dvar, :a), :+, s(:array, s(:dvar, :b))))
=end
    def process_iter(exp)
      exp.shift
      receiver_sexp = exp.first #[:call, [:call, [:lit, 1..10], :andand], :inject]
      if receiver_sexp[0] == :call && matches_andand_invocation(receiver_sexp[1])
        exp.shift
        mono_parameter = Rewrite.gensym()
        s(:and, 
          s(:lasgn, mono_parameter, process_inner_expr(receiver_sexp[1][1])),
          begin
            s(:iter, 
              s(:call, 
                s(:lvar, mono_parameter), 
                *(receiver_sexp[2..-1].map { |inner| process_inner_expr inner })
              ), 
              *(exp.map { |inner| process_inner_expr inner })
            )
          ensure
            exp.clear
          end
        )
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

    def process_call(exp)
      # s(:call, s(:call, s(:lit, :foo), :andand), :bar)
      exp.shift
      # s(s(:call, s(:lit, :foo), :andand), :bar)
      receiver_sexp = exp.first
      if matches_andand_invocation(receiver_sexp) # s(:call, s(:lit, :foo), :andand)
        exp.shift
        # s( :bar )
        mono_parameter = Rewrite.gensym()
        s(:and, 
          s(:lasgn, mono_parameter, process_inner_expr(receiver_sexp[1])),
          begin
            s(:call, 
              s(:lvar, mono_parameter),
              *(exp.map { |inner| process_inner_expr inner }))
          ensure
            exp.clear
          end
        )
      else
        # pass through
        begin
          s(:call,
            *(exp.map { |inner| process_inner_expr inner })
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
    
    def matches_andand_invocation(sexp)
      sexp.respond_to?(:[]) && sexp[0] == :call && sexp[2] == :andand
    end
    
  end

end