require 'pp'
require 'rubygems'
require 'parse_tree'
require 'ruby2ruby'
require 'parse_tree_extensions'

module RewriteRails
  
  class CallByNameProcessor

    def initialize
      convert_outstanding_call_by_name_methods
      method_calls_to_convert = (CallByName.methods - Module.instance_methods).map(&:to_sym)
      method_calls_to_convert.inject({}) { |hash, name| hash.merge(name => CallByName.method(name)) }
      @call_by_thunk = RewriteRails::CallByThunk.new(
        method_calls_to_convert.inject({}) { |hash, name| hash.merge(name => CallByName.method(name)) }
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
        arity = unbound_method.arity
        if arity > 0
          direct_arity = arity
        elsif arity == -1
          direct_arity = 0
        elsif arity < -1
          direct_arity = -arity - 1
        end
        sexp = eval(unbound_method.to_ruby).to_sexp
        rewritten_sexp = RewriteRails::RewriteParametersAsThunkCalls.new(direct_arity).process(sexp)
        proc_ruby = Ruby2Ruby.new.process(rewritten_sexp)
        matchdata = /\Aproc\s+(?:do|\{)\s+(?:\|([^|]*)\|)?((?:.|\s)*)(?:end|\})\Z/.match(proc_ruby) or raise ArgumentError, proc_ruby
        parameter_list, method_body = matchdata[1], matchdata[2]
        method_ruby = "def self.#{method_name}(#{parameter_list || ''}); #{method_body}; end"
        CallByName.class_eval(method_ruby)
        CallByName.send :undef_method, method_name
      end
    end
  
  end

end