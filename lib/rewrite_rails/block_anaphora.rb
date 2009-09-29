$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'parse_tree'
require 'sexp_processor'
require 'sexp'

module RewriteRails
  
  # Adds ...
  class BlockAnaphora < SexpProcessor
    
    include SexpUtilities
    
    ANAPHOR_SYMBOL = :_

=begin
  [:iter, 
    [:call, 
      [:lit, 1], 
      :times, 
      [:arglist]
    ],
    nil, 
    [:call, 
      [:call, 
        nil, 
        :it, 
        [:arglist]
      ], 
      :to_s,
      [:arglist]
    ]
  ]

  =>

  [:iter, 
    [:call, 
      [:lit, 1], 
      :times, 
      [:arglist]
    ], 
    [:lasgn, :it], 
    [:call, 
      [:lvar, :it], 
      :to_s, 
      [:arglist]
    ]
  ]
=end
    def process_iter(exp)
      begin
        type_sexp, call_sexp, arg_list_sexp, block_sexp = exp.map { |inner| 
          process_inner_expr(inner) 
        }
        if arg_list_sexp.nil? && contains_direct_anaphor_reference(prune(block_sexp))
          arg_list_sexp = s(:lasgn, ANAPHOR_SYMBOL)
          block_sexp = convert_anaphor_references(block_sexp)
        end
        s(
          *[type_sexp, call_sexp, arg_list_sexp, block_sexp].map { |inner| 
            process_inner_expr(inner) 
          }
        )
      ensure
        exp.clear
      end
    end
    
    private
    
    def convert_anaphor_references(sexp)
      if sexp.nil?
        nil
      elsif !(sexp.respond_to?(:[]) && sexp.respond_to?(:empty?) && sexp.respond_to?(:first))
        sexp
      elsif sexp.empty?
        []
      elsif sexp.to_a == [:call, nil, ANAPHOR_SYMBOL, [:arglist]]
        s(:lvar, ANAPHOR_SYMBOL)
      else
        s(*sexp.map { |inner| convert_anaphor_references(inner) })
      end
    end
    
    def contains_direct_anaphor_reference(sexp)
      deep_matches_anaphor_reference(prune(sexp))
    end
    
    # prunes a sexp of all blocks, does not return a valid ruby expression
    # must be fixed to allow inner expressions to work
    def prune(sexp)
      if sexp.nil?
        nil
      elsif !list?(sexp)
        sexp
      elsif sexp.empty?
        []
      elsif sexp.first == :iter && (sexp[2].nil? || sexp[2] && sexp[2].to_a == [:lasgn, ANAPHOR_SYMBOL])
         r = sexp[0..-2].map { |inner| prune(inner) }
      else
        sexp.map { |inner| prune(inner) }
      end
    end
    
    def shallow_matches_anaphor_reference(sexp)
      return false unless list?(sexp)
      sexp_a = sexp.to_a
      sexp_a == [:lvar, ANAPHOR_SYMBOL] or sexp_a == [:call, nil, ANAPHOR_SYMBOL, [:arglist]]
    end
    
    def deep_matches_anaphor_reference(sexp)
      shallow_matches_anaphor_reference(sexp) or 
      (list?(sexp) && sexp.detect { |element| deep_matches_anaphor_reference(element) })
    end
    
  end

end