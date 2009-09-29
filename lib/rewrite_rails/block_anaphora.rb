$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'parse_tree'
require 'sexp_processor'
require 'sexp'

module RewriteRails
  
  # Adds ...
  class BlockAnaphora < SexpProcessor
    
    include SexpUtilities
    
    ANAPHOR_SYMBOLS = [:_, :it, :its]
    
    ANAPHOR_PARAMETERS = ANAPHOR_SYMBOLS.inject({}) { |refs, it| 
      refs.merge!({ [:lasgn, it] => it })
      refs
    }
    
    ANAPHOR_REFERENCES = ANAPHOR_SYMBOLS.inject({}) { |refs, it| 
      refs.merge!({ [:lvar, it] => it, [:call, nil, it, [:arglist]] => it })
      refs
    }

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
        if arg_list_sexp.nil? and (anaphor = direct_anaphor_reference_contained(prune(block_sexp)))
          #puts anaphor
          arg_list_sexp = s(:lasgn, anaphor)
          block_sexp = convert_anaphor_references(block_sexp, anaphor)
        end
        s(
          *[type_sexp, call_sexp, arg_list_sexp, block_sexp].map { |inner| 
            process_inner_expr(inner) 
          }
        )
      rescue Exception
        puts "Exception for #{[type_sexp, call_sexp, arg_list_sexp, block_sexp].to_a.inspect}"
      ensure
        exp.clear
      end
    end
    
    private
    
    def convert_anaphor_references(sexp, anaphor_symbol)
      if sexp.nil?
        nil
      elsif !(sexp.respond_to?(:[]) && sexp.respond_to?(:empty?) && sexp.respond_to?(:first))
        sexp
      elsif sexp.empty?
        []
      elsif ANAPHOR_REFERENCES[sexp.to_a]
        s(:lvar, anaphor_symbol)
      else
        s(*sexp.map { |inner| convert_anaphor_references(inner, anaphor_symbol) })
      end
    end
    
    def direct_anaphor_reference_contained(sexp)
      deep_matching_anaphor_reference(prune(sexp))
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
      elsif sexp.first == :iter && (sexp[2].nil? || sexp[2] && ANAPHOR_PARAMETERS[sexp[2].to_a])
         r = sexp[0..-2].map { |inner| prune(inner) }
      else
        sexp.map { |inner| prune(inner) }
      end
    end
    
    def shallow_matching_anaphor_reference(sexp)
      ANAPHOR_REFERENCES[sexp.to_a] if list?(sexp)
    end
    
    def deep_matching_anaphor_reference(sexp)
      shallow_matching_anaphor_reference(sexp) or 
      sexp.map { |element| deep_matching_anaphor_reference(element) }.compact.first if list?(sexp)
    end
    
  end

end