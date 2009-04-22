$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'parse_tree'
require 'sexp_processor'
require 'sexp'

module RewriteRails

  # Initialize with a list of names, e.g.
  #
  #   Extensions.new(:frobbish => [Extension_Home::Fizz, Extension_Home::Bin])
  #
  # It then converts expressions of the form:
  #
  #    arr.frobbish
  #
  # into:
  #
  #    if arr.kind_of?(Extension_Home::Fizz)
  #      Extension_Home::Fizz.frobbish(arr)
  #    elsif arr.kind_of?(Extension_Home::Bin)
  #      Extension_Home::Bin.frobbish(arr)
  #    else
  #      arr.frobbish
  #    end
  class ExtensionProcessor < SexpProcessor
    
    attr_reader :methods_to_modules
    
    Extension_Home = RewriteRails::ExtensionMethods
    Extension_Home_Array = Extension_Home.name.split('::').map(&:to_sym)
    
    def initialize(methods_to_modules = nil)
      @methods_to_modules = methods_to_modules || returning(Hash.new) { |mtm| 
        Extension_Home.constants.map { |konst| 
          Extension_Home.const_get(konst) 
        }.select { |k| 
          k.kind_of?(Module) 
        }.each { |a_module|
          (a_module.methods - Object.methods).each { |method|
            (mtm[method.to_sym] ||= []) << a_module
          }
        }
      }
      super()
    end
    
    def process_iter(exp)
=begin
      s(
        :iter,
        s(:call, s(:lvar, :foo), :frobbish, ...),
        s(:masgn, s(:array, s(:dasgn_curr, :a), s(:dasgn_curr, :b)), nil, nil),
        s(:call, s(:lvar, :a), :+, s(:array, s(:lvar, :b))))
=end
      exp.shift
=begin
      s(
        s(:call, s(:lvar, :foo), :frobbish, ...),
        s(:masgn, s(:array, s(:dasgn_curr, :a), s(:dasgn_curr, :b)), nil, nil),
        s(:call, s(:lvar, :a), :+, s(:array, s(:lvar, :b))))
=end
      sub_expression = exp.first
      # s(:call, s(:lvar, :foo), :frobbish, ...)
      if matches_extension_method_invocation(sub_expression)
=begin
      s(:if, 
        s(:call, s(:call, nil, :expr, s(:arglist)), :kind_of?, s(:arglist, s(:colon2, s(:colon2, s(:const, :RewriteRails), :Extensions), :Array))), 
        s(:iter, 
          s(:call, 
            s(:colon2, s(:colon2, s(:const, :RewriteRails), :Extensions), :Array), 
            :frobbish, 
            s(:arglist, s(:call, nil, :expr, s(:arglist)))
          ), 
          s(:lasgn, :foo), 
          s(:call, nil, :bar, s(:arglist))
        ), 
        s(:call, s(:call, nil, :arr, s(:arglist)), :frobbish, s(:arglist))
      )
=end
        var_sym = RewriteRails.gensym
        assignment_expr = s(:lasgn, var_sym, process_inner_expr(sub_expression[1]))
        receiver_expr = s(:lvar, var_sym)
        method_sym = sub_expression[2]
        arglist = sub_expression[3] || s(:arglist)
        tail_expr = s(:iter,
          s(:call,
            process_inner_expr(receiver_expr),
            method_sym,
            process_inner_expr(arglist)
          ),
          *(exp[1..-1].map { |inner| process_inner_expr(inner.dup) })
        )
        begin
          s(:block,
            assignment_expr,
            methods_to_modules[method_sym].inject(tail_expr) { |s_expr, a_module| 
              module_symbols = a_module.name.split('::').map(&:to_sym)
              original_module_expr = module_expr(module_symbols - Extension_Home_Array)
              extension_module_expr = module_expr(module_symbols)
              s(:if,
                s(:call, process_inner_expr(receiver_expr.dup), :kind_of?, s(:arglist, original_module_expr)),
                s(:iter, 
                  s(:call, 
                    extension_module_expr, 
                    method_sym, 
                    s(:arglist,
                      process_inner_expr(receiver_expr.dup),
                      *(arglist[1..-1].map { |arg| process_inner_expr(arg) })
                    )
                  ), 
                  *(exp[1..-1].map { |arg| process_inner_expr(arg) })
                ),
                s_expr
              )
            }
          )
        ensure
          exp.clear
        end
      else
        # pass through
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
      begin
        if matches_extension_method_invocation(exp)
          var_sym = RewriteRails.gensym
          assignment_expr = s(:lasgn, var_sym, process_inner_expr(exp[1]))
          receiver_expr = s(:lvar, var_sym)
          method_sym = exp[2]
          arglist = exp[3] || s(:arglist)
          tail_expr = s(*(exp.map { |inner| process_inner_expr(inner) }))
          s(:block,
            assignment_expr,
            methods_to_modules[method_sym].inject(tail_expr) { |s_expr, a_module| 
              module_symbols = a_module.name.split('::').map(&:to_sym)
              original_module_expr = module_expr(module_symbols - Extension_Home_Array)
              extension_module_expr = module_expr(module_symbols)
              s(:if,
                s(:call, process_inner_expr(receiver_expr), :kind_of?, s(:arglist, original_module_expr)),
                s(:call, 
                  extension_module_expr, 
                  method_sym, 
                  s(:arglist,
                    process_inner_expr(receiver_expr),
                    *(arglist[1..-1].map { |arg| process_inner_expr(arg) })
                  )
                ), 
                s_expr
              )
            }
          )
        else
          s(*(exp.map { |inner| process_inner_expr(inner) }))
        end
      ensure
        exp.clear
      end
    end
    
    private 
    
    def xerox(it)
      eval(it.to_s)
    end
    
    def module_expr(module_symbols)
      module_symbols[1..-1].inject(s(:const, module_symbols.first)) { |mod_expr, mod_sym| s(:colon2, mod_expr, mod_sym) }
    end
    
    def process_call_or_iter(exp)
      # s(:call, s(:call, s(:lit, :foo), :andand), :bar)
      exp.shift
      # s(s(:call, s(:lit, :foo), :andand), :bar)
      sub_expression = exp.first
      if matches_extension_method_invocation(sub_expression) # s(:call, s(:lit, :foo), :andand)
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
          mono_parameter = ::RewriteRails.gensym()
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
    
    def process_inner_expr(inner)
        inner.kind_of?(Array) ? process(xerox(inner)) : inner
    end
    
    def matches_extension_method_invocation(sexp)
      sexp.respond_to?(:[]) && sexp[0] == :call && methods_to_modules.key?(sexp[2])
    end
    
  end

end