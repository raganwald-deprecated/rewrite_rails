require 'pp'
require 'rubygems'
require 'parse_tree'
require 'ruby2ruby'
require 'parse_tree_extensions'

module RewriteRails
  
  class CallByNameProcessor

    def initialize
      convert_outstanding_call_by_name_methods
      @call_by_thunk = RewriteRails::CallByThunk.new(
        *(CallByName.methods - Module.instance_methods).map(&:to_sym)
      )
    end
  
    def process(sexp)
      @call_by_thunk.process(sexp)
    end
  
    private
  
    def convert_outstanding_call_by_name_methods
      methods_to_convert = CallByName.instance_methods
      methods_to_convert.each do |method_name|
        unbound_method = CallByName.instance_method(method_name)
        sexp = eval(unbound_method.to_ruby).to_sexp
        rewritten_sexp = RewriteRails::RewriteParametersAsThunkCalls.new.process(sexp)
        ruby = Ruby2Ruby.new.process(rewritten_sexp)
        new_proc = CallByName.class_eval(ruby)
        CallByName.class_eval do 
          define_method(method_name, &new_proc)
          module_function method_name.to_sym
        end
        CallByName.send :undef_method, method_name
      end
    end
  
  end

end