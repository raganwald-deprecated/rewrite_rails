require 'pp'
require 'rubygems'
require 'parse_tree'
require 'ruby2ruby'
require 'parse_tree_extensions'

module RewriteRails
  
  module CallByName
  
    class ClassProcessor
    
      NAMES_TO_DIRECT_ARITIES = {}
      
      attr_accessor :methods_converted_on_creation

      def initialize
        outstanding_call_by_name_methods_to_direct_arities = convert_outstanding_call_by_name_methods()
        NAMES_TO_DIRECT_ARITIES.merge! outstanding_call_by_name_methods_to_direct_arities
        self.methods_converted_on_creation = outstanding_call_by_name_methods_to_direct_arities.keys
        method_calls_to_thunkify = (CallByName.methods - Module.instance_methods).map(&:to_sym)
        @call_by_thunk = RewriteRails::CallByThunk.new(
          method_calls_to_thunkify.inject({}) { |hash, name| hash.merge(name => CallByName.method(name)) },
          NAMES_TO_DIRECT_ARITIES
        )
      end
  
      def process(sexp)
        @call_by_thunk.process(sexp)
      end
  
      private
  
      def convert_outstanding_call_by_name_methods
        CallByName.instance_methods.inject({}) do |names_to_direct_arities, method_name|
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
          parameter_list = parameter_list.split(",").map { |_| _[/^\s*(?:\*)?(.*)\s*$/,1] }.join(',')
          method_ruby = "def self.#{method_name}(#{parameter_list || ''}); #{method_body}; end"
          CallByName.class_eval(method_ruby)
          CallByName.send :undef_method, method_name
          names_to_direct_arities.merge(method_name.to_sym => direct_arity)
        end
      end
  
    end
    
  end

end