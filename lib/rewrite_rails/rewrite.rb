require 'pp'
require 'rubygems'
require 'parse_tree'
require 'ruby2ruby'
require 'parse_tree_extensions'

module RewriteRails

  module Rewrite
  
    def self.from_sexp(sexp)
      sexp = Andand.new.process(sexp)
      sexp = StringToProc.new.process(sexp)
    end
    
    class << self
      
      def default_generator
        lambda { :"__#{Time.now.to_i}#{rand(100000)}__" }
      end
      
      def gensym
        (@generator ||= default_generator).call()
      end
        
      def define_gensym(&block)
        @generator = block
      end
        
    end

    # Convert an expression to a sexp by taking a block and stripping
    # the outer proc from it.
=begin
  s(:iter,
    s(:call, nil, :proc, s(:arglist)),
    nil, 
    s(:call, s(:call, nil, :foo, s(:arglist)), :bar, s(:arglist))
  )
=end
    def self.sexp_for &proc
      sexp = proc.to_sexp 
      raise ArgumentError if sexp.length != 4
      raise ArgumentError if sexp[0] != :iter
      raise ArgumentError unless sexp[2].nil?
      sexp[3]
    end

    # Convert an expression to a sexp and then the sexp to an array.
    # Useful for tests where you want to compare results.
    def self.arr_for &proc
      sexp_for(&proc).to_a
    end

    # Convert an object of some type to a sexp, very useful when you have a sexp
    # expressed as a tree of arrays.
    def self.recursive_s(node)
      if node.is_a? Array
        s(*(node.map { |subnode| recursive_s(subnode) }))
      else
        node
      end
    end
    
    def self.dup_s(sexp)
      recursive_s(sexp.to_a)
    end
  
  end
  
end