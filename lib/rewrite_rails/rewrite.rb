require 'pp'

module RewriteRails

  module Rewrite
  
    def self.from_sexp(sexp)
      sexp = Andand.new.process(sexp)
    end

    # Provide a symbol that is extremely unlikely to be used elsewhere.
    # 
    # Rewriters use this when they need to name something. For example,
    # Andand converts code like this:
    #
    #   numbers.andand.inject(&:+)
    #
    # Into:
    #
    #  lambda { |__1234567890__|
    #    if __1234567890__.nil?
    #      nil
    #    else
    #      __1234567890__.inject(&:+)
    #    end
    #  }.call(numbers)
    #
    # It uses Rewrite.gensym to generate __1234567890__.
    #
    def self.gensym
      :"__#{Time.now.to_i}#{rand(100000)}__"
    end
  
  end
  
end