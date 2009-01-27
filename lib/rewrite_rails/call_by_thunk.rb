$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'parse_tree'
require 'sexp_processor'

module RewriteRails
    
  # Initialize with a list of names, e.g.
  #
  #   CallByThunk.new(:foo, :bar)
  #
  # It then converts expressions of the form:
  #
  #    foo(expr1, expr2, ..., exprn)
  #
  # into:
  #
  #    ::RewriteRails::CallByName.foo( lambda { expr1 }, lambda { expr2 }, ..., lambda { exprn })
  #
  # This is handy when combined with RewriteVariablesAsThunkCalls in the following
  # manner: if you rewrite method invocations with CallByThunk and also rewrite the
  # method's body to convert variable references into thunk calls, you now have a
  # method with call-by-name semantics
  #
  
  class CallByThunk < SexpProcessor
    
    def initialize(name_to_method_hash, name_to_direct_arity)
      @name_to_method_hash = name_to_method_hash # we could look this up in CallByName, but we leave it open for future changes
      @name_to_arity = name_to_method_hash.inject({}) do |hash, pair|
        name, method = *pair
        hash.merge(name => method.arity)
      end
      @name_to_direct_arity = name_to_direct_arity
      super()
    end
    
    RECIPIENT_SEXP = RewriteRails.clean { RewriteRails::CallByName }
    CREATOR_SEXP = RewriteRails.clean { RewriteRails::CallByName::P }
    
    def process_call(exp)
      qua = exp.dup
      exp.shift
      recipient = exp.shift
      name = exp.shift
      arity = @name_to_arity[name]
      if arity && recipient.nil?
        thunked = s(:call, RECIPIENT_SEXP, name)
        unless exp.empty?
          arguments = exp.shift
          raise "Do not understand arguments #{arguments}" unless arguments[0] == :arglist
          arguments.shift
          # arguments is now a list of parameters
          direct_arity = @name_to_direct_arity[name]
          splatted = arity > direct_arity
          thunked_arguments = s(:arglist)
          direct_arity.times do
            thunked_arguments <<  s(:iter, 
              s(:call, nil, :proc, s(:arglist)), 
              nil, 
              process(arguments.shift)
            )
          end
          if splatted
            splatted_thunked_arguments = s(:arglist)
            until arguments.empty?
              splatted_thunked_arguments <<  s(:iter, 
                s(:call, nil, :proc, s(:arglist)), 
                nil, 
                process(arguments.shift)
              )
            end
            thunked_arguments << s(:call, CREATOR_SEXP, :new, splatted_thunked_arguments)
          end
          thunked << thunked_arguments
          thunked = eval(thunked.inspect)
        end
      else
        recipient &&= process(recipient)
        thunked = s(:call, recipient, name)
        while !exp.empty?
          it = exp.shift
          if it.kind_of?(Array)
            thunked << process(it)
          else
            thunked << it
          end
        end
      end
      thunked
    end
    
  end
  
end