require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))

def ws(str)
  str.gsub(/\s+/, ' ')
end

def if_then_by_value(test, consequent)
  test && consequent
end

describe RewriteRails::CallByNameProcessor do
  
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
    end
    
    it "should convert the method to use thunks" do
      @it = RewriteRails::CallByNameProcessor.new
      ws(RewriteRails::CallByName.instance_method(:foo).to_ruby).should == ws(proc { |bar| bar.call }.to_ruby)
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
  
end