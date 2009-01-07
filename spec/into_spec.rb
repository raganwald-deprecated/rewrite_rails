require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))

describe RewriteRails::Into do
  
  before(:each) do
    
    RewriteRails::Rewrite.define_gensym do
      :__TEMP__
    end
    
    @it = RewriteRails::Into.new
      
  end
  
  it "should not change normal method invocations" do
    @it.process(RewriteRails.clean { foo.bar }).to_a.should == RewriteRails.clean { foo.bar }.to_a
    @it.process(RewriteRails.clean { foo.bar(5) }).to_a.should == RewriteRails.clean { foo.bar(5) }.to_a
    @it.process(RewriteRails.clean { 5.bar(5) }).to_a.should == RewriteRails.clean { 5.bar(5) }.to_a
    @it.process(RewriteRails.clean { 5.bar(5) do; end }).to_a.should == RewriteRails.clean { 5.bar(5) do; end }.to_a
  end
  
  describe "\#into with a block" do
    
    describe "a block with an argument" do
      
      before(:each) do
        @source = RewriteRails.clean do
          :foo.into { |foo| foo }
        end
        @target = RewriteRails.clean do
          begin
            foo = :foo
            foo
          end
        end
      end
      
      it "should turn the expression into a block" do
        @it.process(@source).to_a.should == @target.to_a
      end
      
    end
    
    describe "a block with no arguments" do
      
      before(:each) do
        @source = RewriteRails.clean do
          foo().into { 'fu' }
        end
        @target = RewriteRails.clean do
          begin
            foo()
            'fu'
          end
        end
      end
      
      it "should turn the expression into a block" do
        @it.process(@source).to_a.should == @target.to_a
      end
      
    end
    
    describe "a block with no statements" do
      
      before(:each) do
        @source = RewriteRails.clean do
          :foo.into { |foo| }
        end
        @target = RewriteRails.clean do
          :foo
        end
      end
      
      it "should turn the expression into a block" do
        @it.process(@source).to_a.should == @target.to_a
      end
      
    end
  
  end

end