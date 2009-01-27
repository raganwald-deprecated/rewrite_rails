require 'forwardable'

class RewriteRails::CallByName::P
  extend Forwardable
  include Enumerable

  def initialize(*lambdas)
    @lambdas = *lambdas
  end

  def each
    @lambdas.each do |l|
      yield l.call
    end
  end
  
  def [](index_or_range)
    case index_or_range
    when Fixnum
      @lambdas[index_or_range].call
    when Range
      self.class.new(*@lambdas[index_or_range])
    else
      raise ArgumentError, "[#{index_or_range}] not implemented for call by name splats"
    end
  end
  
  def first
    @lambdas.first.call
  end
  
  def last
    @lambdas.last.call
  end
  
  def_delegators :@lambdas, :length, :size

end