Call by Name
===

RewriteRails supports creation of things that look like Kernel methods with [Call by Name](http://en.wikipedia.org/wiki/Call-by-value "Evaluation strategy - Wikipedia, the free encyclopedia") semantics. It works like this. First, you write an instance method in the `RewriteRails::CallByName` module:

    RewriteRails::CallByName.class_eval do
      def try_these(*expressions)
        value = token = Object.new
        i = 0
        while i < expressions.length && value == token do
          value = expressions[i] rescue token
          i += 1
        end
        value == token ? nil : value
      end
    end
        
The method I have just described takes a variable number of arguments and tries to assign them to the `value` instance variable. If it manages to do so without raising an exception, the method returns the value. If it cannot do so without raising an exception, the method returns `nil`. We will see in a moment why this is special.

This definition should be placed somewhere that ActiveSupport::Dependencies can find it before you use it, like in `config/initializers`. Now, when you are writing a `.rr` file, you can use `try_these` like this:

    user = try_these(
        http_util.fetch(url, :login_as => :anonymous),
        http_util.fetch(url, :login_as => ['user', 'password']),
        :inauthentic
    )

What will happen? Let's consider the case where `http_util.fetch(url, :login_as => :anonymous)` raises an exception when you try it, but `http_util.fetch(url, :login_as => ['user', 'password'])` does not. Glossing over the fact that `try_these` was written as an instance method of `RewriteRails::CallByName`, in ordinary Ruby the exception would be raised when Ruby started to assemble the parameters to call the `try_these method`. Ruby calls methods by value, so the first thing it does is collect all the values. Something like this:

    temp_1 = http_util.fetch(url, :login_as => :anonymous) # raises exception!
    temp_2 = http_util.fetch(url, :login_as => ['user', 'password'])
    user = try_these(
        temp_1,
        temp_2,
        :inauthentic
    )

So in ordinary Ruby, `try_these` is never invoked. However, RewriteRails does something special. It rewrites the method call to wrap each parameter in a `proc`, a practice called [thunking](http://en.wikipedia.org/wiki/Thunk "Thunk - Wikipedia, the free encyclopedia"). So the method can be called without the arguments raising any exceptions.

Then when the arguments are used inside the method, the procs are invoked. RewriteRails rewrites both the method and each method invocation. Like the rest of RewriteRails, the rewritten code is stored in plain `.rb` files so you can always walk away from RewriteRails or deploy to a server without any rewriting needed.

Why?
---

Although Call by Name semantics are not as powerful as directly rewriting s-expressions, [you can solve most of the problems that require macros with a lot less effort](http://jfkbits.blogspot.com/2008/05/call-by-need-lambda-poor-mans-macro.html "JFKBits: Call by Need Lambda a Poor Man's Macro?"). Also, Call By name in RewriteRails is programmable: You can write your own syntactic abstractions without needing to know anything about s-expressions.

When writing a Call by Name method, you just have to remember three things:

1.  Write it in the RewriteRails::CallByName module;
2.  Invoke it as if it were a top-level or Kernel method;
3.  Remember that it will magically wrap each argument in a `proc` and unwrap it when you need it.

A Peek Behind the Curtain
---

Here're a few sample methods from the test spec:

    RewriteRails::CallByName.class_eval do
    
      def if_then(test, consequent)
        test and consequent
      end
      
      def try_these(*expressions)
        value = token = Object.new
        i = 0
        while i < expressions.length && value == token do
          value = expressions[i] rescue token
          i += 1
        end
        value == token ? nil : value
      end
      
    end

And here is the rewritten copy of `call_by_name.rb`:

    module RewriteRails::CallByName
      def self.if_then(test, consequent)
        (test.call and consequent.call)
      end
  
      def self.try_these(expressions)
        value = token = Object.new
        i = 0
        while ((i < expressions.length) and (value == token)) do
          value = expressions[i] rescue token
          i = (i + 1)
        end
        (value == token) ? (nil) : (value)
      end
    end

If we write some code (in a `.rr` file, of course) to call our methods:

    class TestCallByName
  
      def test1
        if_then foo == bar, pizzle()
      end

      def test2
        user = try_these(
            http_util.fetch(url, :login_as => :anonymous),
            http_util.fetch(url, :login_as => ['user', 'password']),
            :inauthentic
        )
      end
  
    end

It is rewritten as:

    class TestCallByName
    
      def test1
        RewriteRails::CallByName.if_then(proc { (foo == bar) }, proc { pizzle })
      end
      
      def test2
        user = RewriteRails::CallByName.try_these(
          RewriteRails::CallByName::P.new(
            proc { http_util.fetch(url, :login_as => :anonymous) }, 
            proc { http_util.fetch(url, :login_as => (["user", "password"])) }, 
            proc { :inauthentic }
          )
        )
      end
      
    end

For methods with a splatted parameter, RewriteRails makes use of a helper class, `RewriteRails::CallByName::P`. As you expect, it is written out in the rewritten folder as well.

Github user [andhapp](http://github.com/andhapp) asked a question: *I was going through the CallByName documentation provided and noticed something unusual. Under "A Peek Behind The Curtain", there is a code snippet evaluating a class (class\_eval). The following code snippet shows the regenerated .rb file but now the same methods are shown as class methods. Isn't class\_eval meant to produce instance methods as opposed to class methods? In the next few code snippets, the methods are indeed used as class methods. May be I am missing an important point. I thought this might be a glitch in the documentation or may be I am not thinking straight. Either way, I would be extremely delighted if you could please enlighten me.* 

My answer: *You use them as if they were instance methods defined in Kernel, so I designed it so that you would write them as instance methods. RewriteRails happens to rewrite them as class methods and then rewrite your code to call them as such, but that it an "implementation detail," as it were. To your .rr code they look like instance methods.*