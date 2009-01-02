require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))

describe RewriteRails::StringToBlock do
  
  before(:each) do
    @it = RewriteRails::StringToBlock.new
  end
  
  it "should not change normal method invocations" do
    @it.process(RewriteRails.clean { foo.bar }).to_a.should == RewriteRails.clean { foo.bar }.to_a
    @it.process(RewriteRails.clean { foo.bar(5) }).to_a.should == RewriteRails.clean { foo.bar(5) }.to_a
    @it.process(RewriteRails.clean { 5.bar(5) }).to_a.should == RewriteRails.clean { 5.bar(5) }.to_a
    @it.process(RewriteRails.clean { 5.bar(5) do; end }).to_a.should == RewriteRails.clean { 5.bar(5) do; end }.to_a
  end
  
  it "should not change block_pass for things that aren't string literals" do
    @it.process(RewriteRails.clean { foo.bar(&:bash) }).to_a.should == RewriteRails.clean { foo.bar(&:bash) }.to_a
    @it.process(RewriteRails.clean { foo.bar(&('fu' + 'bar')) }).to_a.should == RewriteRails.clean { foo.bar(&('fu' + 'bar')) }.to_a
  end
  
  it "should process procs with one parameter" do
    @it.process(RewriteRails.clean { foo.bar(&'bash') }).to_a.should == RewriteRails.clean { foo.bar() { |bash| bash } }.to_a
  end
  
  it "should process procs with one implied parameter" do
    @it.process(RewriteRails.clean { foo.bar(&'* 2') }).to_a.should == RewriteRails.clean { foo.bar() { |$left| $left * 2 } }.to_a
  end
  
end