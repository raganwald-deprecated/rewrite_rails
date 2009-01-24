require 'pp'
require 'rubygems'
require 'parse_tree'
require 'ruby2ruby'
require 'parse_tree_extensions'
  
class RewriteRails::CallByNameProcessor

  def initialize
    convert_outstanding_call_by_name_methods
    @call_by_thunk = RewriteRails::CallByThunk.new(
      *RewriteRails::CallByName::CONVERTED.map(&:to_sym)
    )
  end
  
  def process(sexp)
    @call_by_thunk.process(sexp)
  end
  
  private
  
  def convert_outstanding_call_by_name_methods
    methods_to_convert = RewriteRails::CallByName.instance_methods - RewriteRails::CallByName::CONVERTED
    o = returning(Object.new) do |o|
      o.extend(RewriteRails::CallByName)
    end
    methods_to_convert.each do |method_name|
      unbound_method = RewriteRails::CallByName.instance_method(method_name)
      sexp = eval(unbound_method.to_ruby).to_sexp
      rewritten_sexp = RewriteRails::RewriteParametersAsThunkCalls.new.process(sexp)
      ruby = Ruby2Ruby.new.process(rewritten_sexp)
      new_proc = RewriteRails::CallByName.class_eval(ruby)
      RewriteRails::CallByName.class_eval do 
        define_method(method_name, &new_proc)
        module_function method_name.to_sym
      end
      RewriteRails::CallByName::CONVERTED << method_name
    end
  end
  

end