$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'parse_tree'
require 'sexp_processor'

module RewriteRails
    
  # Initialize with a list of names, e.g.
  #   CallByThunk.new(:foo, :bar)
  #
  # It then converts expressions of the form:
  #
  #    foo(expr1, expr2, ..., exprn)
  #
  # into:
  #
  #    foo.call( lambda { expr1 }, lambda { expr2 }, ..., lambda { exprn })
  #
  # This is handy when combined with RewriteVariablesAsThunkCalls in the following
  # manner: if you rewrite function invocations with CallByThunk and also rewrite the
  # function's body to convert variable references into thunk calls, you now have a
  # function with call-by-name semantics
  #
  class CallByThunk < SexpProcessor
    
    def initialize(*functions_to_thunkify)
      @functions_to_thunkify = functions_to_thunkify
      super()
    end
    
    RECIPIENT_SEXP = RewriteRails.clean { RewriteRails::CallByName }
    
    def process_call(exp)
      qua = exp.dup
      exp.shift
      recipient = exp.shift
      name = exp.shift
      if @functions_to_thunkify.include?(name) && recipient.nil?
        thunked = s(:call, RECIPIENT_SEXP, name)
        unless exp.empty?
          arguments = exp.shift
          raise "Do not understand arguments #{arguments}" unless arguments[0] == :arglist
          arguments.shift
          thunked_arguments = s(:arglist)
          until arguments.empty?
            thunked_arguments <<  s(:iter, 
              s(:call, nil, :proc, s(:arglist)), 
              nil, 
              process(arguments.shift)
            )
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