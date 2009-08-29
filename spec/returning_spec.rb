require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))

describe RewriteRails::Returning do
  
    before(:each) do
    
    RewriteRails.define_gensym do
      :__TEMP__
    end
    
    @it = RewriteRails::Returning.new
      
  end
  
  it "should not change normal top-level invocations" do
    @it.process(RewriteRails.clean { foo() }).to_a.should == RewriteRails.clean { foo() }.to_a
    @it.process(RewriteRails.clean { foo(5) }).to_a.should == RewriteRails.clean { foo(5) }.to_a
    @it.process(RewriteRails.clean { foo() { |bar| bar } }).to_a.should == RewriteRails.clean { foo() { |bar| bar } }.to_a
    @it.process(RewriteRails.clean { foo(5) { |bar| bar } }).to_a.should == RewriteRails.clean { foo(5) { |bar| bar } }.to_a
  end
  
  describe "a single line block with a parameter" do
    
    before(:each) do
      @source = RewriteRails.clean do
        returning(:foo) do |bar|
          bar + bar
        end
      end
      @target = RewriteRails.clean do
        # this doesn't work because the processor is not persistant!
        lambda do |bar|
          bar + bar
          bar
        end.call(:foo)
      end
    end
      
    it "should insert the parameter into the block and revise the scope" do
      @it.process(@source).to_a.should == @target.to_a
    end
    
  end
  
end