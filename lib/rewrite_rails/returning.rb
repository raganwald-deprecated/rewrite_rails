$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'parse_tree'
require 'sexp_processor'
require 'sexp'

module RewriteRails
  
  # Adds the k combinator to Ruby
  #
  # returning(expression) do |p|
  #   ...
  #   other_expression
  # end
  #
  # => expression instead of other_expression nearly all of the time
  #
  class Returning < SexpProcessor
  
    def self.returning(value)
      if block_given?
        return yield(value)
      else
        value
      end
    end    
    
    # [:iter, 
    #   [:call, nil, :returning, [:arglist, [:lit, :foo]]], 
    #   [:lasgn, :bar], 
    #   [:call, [:lvar, :bar], :+, [:arglist, [:lvar, :bar]]
    # ]
    #
    def process_iter(exp)
      exp.shift
      sub_expression = exp.first #[:call, nil, :returning, [:arglist, [:lit, :foo]]]
      if sub_expression[0..2].to_a == [:call, nil, :returning] && 
          sub_expression[3] && 
          sub_expression[3][0] == :arglist &&
          exp[1].respond_to?(:[]) && exp[1][0] == :lasgn
        arg = sub_expression[3][1]
        param_sym = exp[1][1]
        block_or_arg = exp[2]
        block_statements = if block_or_arg
            if block_or_arg.respond_to?(:[])
              if block_or_arg.first
                if block_or_arg.first == :block
                  block_or_arg.shift
                  block_or_arg.to_a
                else
                  [block_or_arg]
                end
              else
                []
              end
            else
              [block_or_arg]
            end
          else
            []
          end
        block_statements << s(:lvar, param_sym)
        begin
          # [:call, 
          #   [:iter, 
          #     [:call, nil, :lambda, [:arglist]], 
          #     [:lasgn, :bar], 
          #     [:block, [:call, [:lvar, :bar], :+, [:arglist, [:lvar, :bar]]], [:lvar, :bar]]
          #   ], 
          #   :call, 
          #   [:arglist, [:lit, :foo]]
          # ]
          s(:call,
            s(:iter,
              s(:call, nil, :lambda, s(:arglist)),
              s(:lasgn, param_sym),
              s(:block,
                *(block_statements.map { |inner| process_inner_expr(inner) })
              )
            ),
            :call,
            s(:arglist, process_inner_expr(arg))
          )
        ensure
          exp.clear
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
    
  end
  
end