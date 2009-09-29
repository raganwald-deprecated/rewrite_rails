require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))

describe RewriteRails::BlockAnaphora do
  
  before(:each) do
    
    RewriteRails.define_gensym do
      :__TEMP__
    end
    
    @it = RewriteRails::BlockAnaphora.new
      
  end
  
  it "should not change foo.bar" do
    @it.process(RewriteRails.clean { foo.bar }).to_a.should == RewriteRails.clean { foo.bar }.to_a
  end
  
  it "should not change foo.bar(5)" do
    @it.process(RewriteRails.clean { foo.bar(5) }).to_a.should == RewriteRails.clean { foo.bar(5) }.to_a
  end
  
  it "should not change 5.bar(5)" do
    @it.process(RewriteRails.clean { 5.bar(5) }).to_a.should == RewriteRails.clean { 5.bar(5) }.to_a
  end
  
  describe "it anaphora with a block" do
    
    describe "a block with an argument" do
      
      before(:each) do
        @source = RewriteRails.clean do
          1.times { |foo| foo }
        end
        @target = RewriteRails.clean do
          1.times { |foo| foo }
        end
      end
      
      it "should not change the block" do
        @it.process(@source).to_a.should == @target.to_a
      end
      
    end
    
    describe "a block with no arguments that doesn't use the anaphor" do
      
      before(:each) do
        @source = RewriteRails.clean do
          1.times { 'fu' }
        end
        @target = RewriteRails.clean do
          1.times { 'fu' }
        end
      end
      
      it "should not add the anaphor" do
        @it.process(@source).to_a.should == @target.to_a
      end
      
    end
    
    describe "a block with no arguments that uses the anaphor" do
      
      before(:each) do
        @source = RewriteRails.clean do
          1.times { it.to_s }
        end
        @target = RewriteRails.clean do
          1.times { |it| it.to_s }
        end
      end
      
      it "should turn the expression into a block" do
        @it.process(@source).to_a.should == @target.to_a
      end
      
    end
      
    describe "inner anaphor" do
      
      before(:each) do
        @source = RewriteRails.clean do
          1.times { 
            5.times {  
              it.to_s
            }
          }
        end
        @target = RewriteRails.clean do
          1.times { 
            5.times { |it|  
              it.to_s
            }
          }
        end
      end
      
      it "should add the anaphor to the inner block" do
        @it.process(@source).to_a.should == @target.to_a
      end
      
    end
      
    describe "outer anaphor" do
      
      before(:each) do
        @source = RewriteRails.clean do
          1.times { 
            5.times { |n|  
              puts n
            }
            puts it
          }
        end
        @target = RewriteRails.clean do
          1.times { |it|  
            5.times { |n|  
              puts n
            }
            puts it
          }
        end
      end
      
      it "should add the anaphor to the outer block" do
        @it.process(@source).to_a.should == @target.to_a
      end
      
    end
      
    describe "neither anaphor" do
      
      before(:each) do
        @source = RewriteRails.clean do
          1.times { 
            5.times { |n|  
              puts n
            }
            puts 'it'
          }
        end
        @target = RewriteRails.clean do
          1.times { 
            5.times { |n|  
              puts n
            }
            puts 'it'
          }
        end
      end
      
      it "shouldn't add the anaphor to either block" do
        @it.process(@source).to_a.should == @target.to_a
      end
      
    end
  
  end
  
  describe "\_ anaphora with a block" do
    
    describe "a block with an argument" do
      
      before(:each) do
        @source = RewriteRails.clean do
          1.times { |foo| foo }
        end
        @target = RewriteRails.clean do
          1.times { |foo| foo }
        end
      end
      
      it "should not change the block" do
        @it.process(@source).to_a.should == @target.to_a
      end
      
    end
    
    describe "a block with no arguments that doesn't use the anaphor" do
      
      before(:each) do
        @source = RewriteRails.clean do
          1.times { 'fu' }
        end
        @target = RewriteRails.clean do
          1.times { 'fu' }
        end
      end
      
      it "should not add the anaphor" do
        @it.process(@source).to_a.should == @target.to_a
      end
      
    end
    
    describe "a block with no arguments that uses the anaphor" do
      
      before(:each) do
        @source = RewriteRails.clean do
          1.times { _.to_s }
        end
        @target = RewriteRails.clean do
          1.times { |_| _.to_s }
        end
      end
      
      it "should turn the expression into a block" do
        @it.process(@source).to_a.should == @target.to_a
      end
      
    end
      
    describe "inner anaphor" do
      
      before(:each) do
        @source = RewriteRails.clean do
          1.times { 
            5.times {  
              _.to_s
            }
          }
        end
        @target = RewriteRails.clean do
          1.times { 
            5.times { |_|  
              _.to_s
            }
          }
        end
      end
      
      it "should add the anaphor to the inner block" do
        @it.process(@source).to_a.should == @target.to_a
      end
      
    end
      
    describe "outer anaphor" do
      
      before(:each) do
        @source = RewriteRails.clean do
          1.times { 
            5.times { |n|  
              puts n
            }
            puts _
          }
        end
        @target = RewriteRails.clean do
          1.times { |_|  
            5.times { |n|  
              puts n
            }
            puts _
          }
        end
      end
      
      it "should add the anaphor to the outer block" do
        @it.process(@source).to_a.should == @target.to_a
      end
      
    end
      
    describe "neither anaphor" do
      
      before(:each) do
        @source = RewriteRails.clean do
          1.times { 
            5.times { |n|  
              puts n
            }
            puts 'it'
          }
        end
        @target = RewriteRails.clean do
          1.times { 
            5.times { |n|  
              puts n
            }
            puts 'it'
          }
        end
      end
      
      it "shouldn't add the anaphor to either block" do
        @it.process(@source).to_a.should == @target.to_a
      end
      
    end
  
  end

end