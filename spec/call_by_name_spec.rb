require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))

def ws(str)
  str.gsub(/\s+/, ' ')
end

def if_then_by_value(test, consequent)
  test && consequent
end

def eval_processed &block
  eval(Ruby2Ruby.new.process(
    RewriteRails::CallByNameProcessor.new.process(RewriteRails.clean(&block))
  ))
end

describe RewriteRails::CallByNameProcessor do
  
  describe "when a method returning nil is defined" do
    
    before(:each) do
      RewriteRails::CallByName.class_eval do
        def returning_nil(bar)
          bar.do_something()
          return nil
        end
      end
      @it = RewriteRails::CallByNameProcessor.new
    end
    
    it "should convert the method including the return of nil" do
      ws(RewriteRails::CallByName.method(:returning_nil).unbind.to_ruby).should == 
        ws(proc do |bar|
          bar.call.do_something()
          return nil
        end.to_ruby)
    end
    
  end
  
  describe "when a simple method is defined" do
    
    before(:each) do
      RewriteRails::CallByName.class_eval do
        def foo(bar)
          bar
        end
        def bar(bash, blitz)
          bash + blitz
        end
      end
      @it = RewriteRails::CallByNameProcessor.new
    end
    
    it "should convert the method to use thunks" do
      ws(RewriteRails::CallByName.method(:foo).unbind.to_ruby).should == ws(proc { |bar| bar.call }.to_ruby)
    end
    
    it "should convert a method call to supply one thunk" do
      @it = RewriteRails::CallByNameProcessor.new
      ws(Ruby2Ruby.new.process(
        @it.process(
          RewriteRails.clean { foo(1 + 1) }
        )
      )).should == ws(Ruby2Ruby.new.process(RewriteRails.clean { RewriteRails::CallByName.foo(proc { 1 + 1 }) }))
    end
    
    it "should convert a method call to supply multiple thunks" do
      @it = RewriteRails::CallByNameProcessor.new
      ws(Ruby2Ruby.new.process(
        @it.process(
          RewriteRails.clean { bar(1 + 1, 1 - 1) }
        )
      )).should == ws(Ruby2Ruby.new.process(RewriteRails.clean { RewriteRails::CallByName.bar(proc { 1 + 1 }, proc { 1 - 1 }) }))
    end
    
    describe "maybe" do
      
      before(:each) do
        RewriteRails::CallByName.class_eval do
          def if_then(test, consequent)
            test && consequent
          end
        end
      end
      
      it "should not have side-effects in a false case" do
        @it = RewriteRails::CallByNameProcessor.new
        $foo = nil
        eval(Ruby2Ruby.new.process(
          @it.process(
            RewriteRails.clean { if_then(false, $foo = :foo) }
          )
        ))
        $foo.should be_nil
      end
      
      it "should have side-effects in a true case" do
        @it = RewriteRails::CallByNameProcessor.new
        $foo = nil
        eval(Ruby2Ruby.new.process(
          @it.process(
            RewriteRails.clean { if_then(true, $foo = :foo) }
          )
        ))
        $foo.should_not be_nil
      end
      
      it "should have side_effects in a normal method case" do
        $foo =  nil
        if_then_by_value(false, $foo = :foo)
        $foo.should_not be_nil
      end
      
    end
    
  end
  
  describe "return keyword" do
    
    describe "hand rolled" do
      
      before(:each) do
        RewriteRails::CallByName.class_eval do
          def self.hand_returner(foo)
            1.times do
              return foo.call
            end
          end
        end     
      end
      
      it "should return from inside a block" do
        RewriteRails::CallByName.hand_returner(proc { :foo }).should == :foo
      end
      
    end
    
    describe "processed" do
      
      before(:each) do
        RewriteRails::CallByName.class_eval do
          def returner(foo)
            1.times do
              return foo
            end
          end
        end
        @it = RewriteRails::CallByNameProcessor.new  
      end
      
      it "should return from inside a block" do
        eval_processed { returner(:foo) }.should == :foo
      end
      
    end
    
  end
  
end