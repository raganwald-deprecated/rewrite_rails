$:.unshift File.dirname(__FILE__)

module RewriteRails
  
  # Adds ...
  module SexpUtilities
    
    def truthy?(sexp)
      sexp.respond_to?(:[]) && (sexp[0] == :true || sexp[0] == :lit || sexp[0] == :str || sexp[0] == :array)
    end
    
    def falsy?(sexp)
      sexp.respond_to?(:[]) && (sexp[0] == :nil || sexp[0] == :false)
    end
    
    def list?(sexp)
      sexp.respond_to?(:[]) && sexp.respond_to?(:empty?) && sexp.respond_to?(:first)
    end
    
    def process_inner_expr(inner)
        inner.kind_of?(Array) ? process(inner) : inner
    end
    
  end
  
end