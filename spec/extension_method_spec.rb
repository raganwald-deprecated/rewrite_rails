require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))
  
module ExtensionMethods
  
  class Object
    
    def self.into(value)
      yield value
    end
    
    def self.to_backwards_string(s)
      s.to_s.reverse
    end
    
  end
  
  class Numeric
    
    def self.squared(value)
      if block_given?
        (yield value) ^ 2
      else
        value ^ 2
      end
    end
    
  end
  
end

describe RewriteRails::ExtensionProcessor do
  
  before(:each) do
    
    RewriteRails.define_gensym do
      :__TEMP__
    end
    
    @it = RewriteRails::ExtensionProcessor.new
    
  end
  
  describe "extending subclasses of object" do
    
    it "should transform a simple call into a helper" do
      @it.process(RewriteRails.clean { 1.squared }).should == RewriteRails.clean do
        begin
          __TEMP__ = 1
          if __TEMP__.kind_of?(Numeric)
            ExtensionMethods::Numeric.squared(__TEMP__)
          else
            __TEMP__.squared
          end
        end
      end
    end
    
    it "should transform an iterator call into a helper" do
      @it.process(RewriteRails.clean { 2.squared { |n| n * n } }).should == RewriteRails.clean do
        begin
          __TEMP__ = 2
          if __TEMP__.kind_of?(Numeric)
            ExtensionMethods::Numeric.squared(__TEMP__) { |n| n * n }
          else
            __TEMP__.squared { |n| n * n }
          end
        end
      end
    end
    
  end
  
  describe "extending Object" do
    
    it "should transform an iterator call into a helper" do
      @it.process(RewriteRails.clean { 3.into { |n| n * n } }).should == RewriteRails.clean do
        begin
          __TEMP__ = 3
          ExtensionMethods::Object.into(__TEMP__) { |n| n * n }
        end
      end
    end
    
  end
  
end