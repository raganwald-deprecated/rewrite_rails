$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'parse_tree'
require 'sexp_processor'
require 'sexp'

module RewriteRails
  
  class StringToBlock < SexpProcessor
    
=begin
  RewriteRails::Rewrite.sexp_for { foo.bar(&'bash') }.to_a  => 
    [:call, 
      [:call, nil, :foo, [:arglist]], 
      :bar, 
      [:arglist, 
        # ...,
        [:block_pass, [:str, "bash"]]
      ]
    ]
=end
    # def process_iter(exp)
    #   begin
    #     s(
    #       *(exp.map { |inner| process_inner_expr(inner) })
    #     )
    #   ensure
    #     exp.clear
    #   end
    # end
      
    def process_call(exp)
      # s(:call, 
      #  s(:call, nil, :foo, s(:arglist)), :bar, s(:arglist, s(:block_pass, s(:str, "bash"))))
      exp.shift
      # s(
      #  s(:call, nil, :foo, s(:arglist)), 
      # :bar, 
      # s(:arglist, ..., s(:block_pass, s(:str, "bash"))))
      target_string = extract_target_string(exp) and begin
=begin
        [:iter, 
          [:call, [:call, nil, :foo, [:arglist]], :bar, [:arglist, [:lit, :blitz]]], 
          nil, 
          [:call, nil, :bash, [:arglist]]
        ]

        [:iter, 
          [:call, [:call, nil, :foo, [:arglist]], :bar, [:arglist, [:lit, :blitz]]], 
          [:lasgn, :_], 
          [:call, nil, :bash, [:arglist, [:lvar, :_]]]
        ]
        
        [:iter, 
          [:call, nil, :proc, [:arglist]], 
          [:lasgn, :_], 
          [:call, nil, :bash, [:arglist, [:lvar, :_]]]
        ]
=end
        begin
          target_proc = proc_for(target_string)
          result_sexp = target_proc.to_sexp
          inner_call_expr = s(:call,
            process_inner_expr(exp[0]), # receiver
            process_inner_expr(exp[1]), # method
            process_inner_expr(exp[2][0..-2])  # arguments minus the block_pass
          )
          s(:iter,
            inner_call_expr,
            *(result_sexp[2..-1].map { |inner| process_inner_expr(inner) })
          )
        ensure
          exp.clear
        end
    end or begin
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
    
    def process_inner_expr(inner)
        inner.kind_of?(Array) ? process(inner) : inner
    end
    
    def extract_target_string(sexp)
      # s(
      #  s(:call, nil, :foo, s(:arglist)), 
      # :bar, 
      # s(:arglist, ..., s(:block_pass, s(:str, "bash"))))
      sexp.respond_to?(:last) && arg_exp = sexp.last and begin
        arg_exp.respond_to?(:first) && arg_exp.first == :arglist && last_arg = arg_exp.last and begin
          last_arg.respond_to?(:first) && last_arg.first == :block_pass && target_expr = last_arg.last and begin
            target_expr.respond_to?(:first) && target_expr.first == :str && target_expr.last
          end
        end
      end
    end
    
    def proc_for(proc_str)
      params = []
      expr = proc_str
      sections = expr.split(/\s*->\s*/m)
      if sections.length > 1 then
          eval sections.reverse!.inject { |e, p| "(Proc.new { |#{p.split(/\s/).join(', ')}| #{e} })" }
      elsif expr.match(/\b_\b/)
          eval "Proc.new { |_| #{expr} }"
      else
          leftSection = expr.match(/^\s*(?:[+*\/%&|\^\.=<>\[]|!=)/m)
          rightSection = expr.match(/[+\-*\/%&|\^\.=<>!]\s*$/m)
          if leftSection || rightSection then
              if (leftSection) then
                  params.push('$left')
                  expr = '$left' + expr
              end
              if (rightSection) then
                  params.push('$right')
                  expr = expr + '$right'
              end
          else
              proc_str.gsub(
                  /(?:\b[A-Z]|\.[a-zA-Z_$])[a-zA-Z_$\d]*|[a-zA-Z_$][a-zA-Z_$\d]*:|self|arguments|'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*"/, ''
              ).scan(
                /([a-z_$][a-z_$\d]*)/i
              ) do |v|  
                params.push(v) unless params.include?(v)
              end
          end
          eval "Proc.new { |#{params.join(', ')}| #{expr} }"
      end
    end
    
  end

end