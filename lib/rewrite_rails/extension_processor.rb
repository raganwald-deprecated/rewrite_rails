$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'parse_tree'
require 'sexp_processor'
require 'sexp'

module RewriteRails

  # TODO: Re-document
  class ExtensionProcessor < SexpProcessor
    
    attr_reader :methods_to_modules
    
    def initialize()
      @scope_stack = ['::ExtensionMethods']
      @methods_to_modules = compute_methods_to_modules('::ExtensionMethods')
      super()
    end
    
    # Scopes is a list of fully qualified scopes that presumably exist
    def compute_methods_to_modules(scope_name)
      returning(Hash.new) do |mtm|
        sub_scopes = scope_name.split('::')
        fully_qualified_sub_scopes = (0..(sub_scopes.length - 2)).map { |n| sub_scopes[0..n] + ['ExtensionMethods'] }
        xm_homes = (['RewriteRails::ExtensionMethods'] + (fully_qualified_sub_scopes.map { |sub|
          sub.join('::')
        })).map { |n|
          begin
            eval(n)
          rescue NameError => ne
            nil
          end
        }.compact
        xm_homes.each do |xm_home|
          xm_home.constants.map { |konst| 
            xm_home.const_get(konst) 
          }.select { |k| 
            k.kind_of?(Module) 
          }.each { |a_module|
            (a_module.methods - Object.methods).each { |method|
              (mtm[method.to_sym] ||= []) << a_module
            }
          }
        end
      end
    end
    
    # handle nesting here
    def process_module(exp)
      inner_process_scope(exp)
    end
    def process_class(exp)
      inner_process_scope(exp)
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
      if matches_subclass_extension_method_invocation(sub_expression)
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
              extension_module_expr = module_expr(module_symbols)
              if unextended(module_symbols).join('::') == ::Object.name
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
                )
              else
                original_module_expr = module_expr(unextended(module_symbols))
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
              end
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
        if matches_subclass_extension_method_invocation(exp)
          var_sym = RewriteRails.gensym
          assignment_expr = s(:lasgn, var_sym, process_inner_expr(exp[1]))
          receiver_expr = s(:lvar, var_sym)
          method_sym = exp[2]
          arglist = exp[3] || s(:arglist)
          tail_expr = s(
            :call,
            receiver_expr,
            *(exp[2..-1].map { |inner| process_inner_expr(inner) })
          )
          s(:block,
            assignment_expr,
            methods_to_modules[method_sym].inject(tail_expr) { |s_expr, a_module| 
              module_symbols = a_module.name.split('::').map(&:to_sym)
              extension_module_expr = module_expr(module_symbols)
              if unextended(module_symbols).join('::') == ::Object.name
                s(:call, 
                  extension_module_expr, 
                  method_sym, 
                  s(:arglist,
                    process_inner_expr(receiver_expr),
                    *(arglist[1..-1].map { |arg| process_inner_expr(arg) })
                  )
                )
              else
                original_module_expr = module_expr(unextended(module_symbols))
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
              end
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
    
    # handle nesting here
    def inner_process_scope(exp)
      sym = exp.shift
      name_expr = exp.shift
      if name_expr.respond_to?(:[])
        current_scope_name = Ruby2Ruby.new.process(xerox(name_expr))
      else
        current_scope_name = name_expr.to_s
      end
      if @scope_stack.last
        current_scope_name = "#{@scope_stack.last}::#{current_scope_name}"
      end
      begin
        @scope_stack.push(current_scope_name)
        @old_methods_to_modules = @methods_to_modules
        @methods_to_modules = compute_methods_to_modules(current_scope_name)
        s(sym,
          name_expr,
          *(exp.map { |inner| process_inner_expr(inner) })
        )
      ensure
        @methods_to_modules = @old_methods_to_modules
        @scope_stack.pop
        exp.clear
      end
    end
    
    # remove everything up to 'ExtensionMethods'
    def unextended(symbol_list)
      found = (0..(symbol_list.length - 1)).map { |n| 
        symbol_list[n..-1] 
      }.detect { |sub_list| 
        sub_list.first.to_s == 'ExtensionMethods' 
      }
      if found
        found[1..-1]
      else
        symbol_list
      end
    end
    
    def xerox(it)
      eval(it.to_s)
    end
    
    def module_expr(module_symbols)
      module_symbols[1..-1].inject(s(:const, module_symbols.first)) { |mod_expr, mod_sym| s(:colon2, mod_expr, mod_sym) }
    end
    
    def process_inner_expr(inner)
        inner.kind_of?(Array) ? process(xerox(inner)) : inner
    end
    
    def matches_subclass_extension_method_invocation(sexp)
      sexp.respond_to?(:[]) && sexp[0] == :call && methods_to_modules.key?(sexp[2])
    end
    
  end

end