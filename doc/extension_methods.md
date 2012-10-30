Extension Methods
===

> An **extension method** is a new language feature of C# starting with the 3.0 specification, as well as Visual Basic.NET starting with 9.0 and Oxygene with 2.0. Extension methods enable you to "add" methods to existing types without creating a new derived type, recompiling, or otherwise modifying the original type. Extension methods are a special kind of static method, but they are called as if they were instance methods on the extended type. For client code written in C# and Visual Basic, there is no apparent difference between calling an extension method and the methods that are actually defined in a type. --[Wikipedia](http://en.wikipedia.org/wiki/Extension_method "Extension Methods")

With [RewriteRails](http://github.com/raganwald-deprecated/rewrite_rails "raganwald's rewrite_rails"), you can now write Extension Methods for your Ruby on Rails projects. Just like in C#, you can "add" methods to existing classes or module (like Enumerable) without modifying the original class or module. The benefit is that your changes *never* [conflict with other code](http://github.com/raganwald/homoiconic/blob/master/2009-04-08/sick.md#readme "I'm Sick of this Shit"). The headaches of opening core classes simply go away.

**How to Write an Extension Method**

First, you add a new class or module to the `RewriteRails::ExtensionMethods` module that mimics the class or module of the objects that will handle the method:

    module RewriteRails
      module ExtensionMethods
      
        module Enumerable
        end
        
      end
    end
    
This tells RewriteRails that we want to work with the standard library's Enumerable module. Since or new Enumerable module is nested inside RewriteRails::ExtensionMethods, our work will not conflict with the existing Enumerable module in any way. Next, we add **class** methods to our new class. Here's an example:

    module RewriteRails
      module ExtensionMethods
      
        module Enumerable
        
          def self.sum(arr, identity = 0, &block)
            return identity unless arr.size > 0
            
            if block_given?
              arr.map(&block).sum
            else
              arr.flatten.inject(&:+)
            end
          end
          
        end
        
      end
    end
        
(This definition should be placed somewhere that ActiveSupport::Dependencies can find it before you use it, like in `lib/rewrite_rails/extension_methods/enumerable.rb`.) The method we have just written recursively sums an enumerable. Since it is written as a class method, we could use it by hand as follows:

    RewriteRails::ExtensionMethods::Enumerable.sum([[1,2], [3,4], [5,6]])
     => 21

The advantage of putting our own definition in a separate module is that if someone else monkey-patches the core library to add their own #sum method, we will not have a conflict. Why does this matter? Imagine they wrote this:

    module Enumerable
    
      def sum(identity = 0, &block)
        return identity unless size > 0

        if block_given?
          map(&block).sum
        else
          inject { |sum, element| sum + element }
        end
      end
      
    end

Your version and their version give different results for an array of arrays. While your version computes the sum of [[1,2], [3,4], [5,6]] as 21, their version does something else entirely:

    [[1,2], [3,4], [5,6]].sum
      => [1, 2, 3, 4, 5, 6]
      
Having two versions of the same method that give different results is obviously a conflict. Had you written your version by opening up the Enumerable module and adding #sum, you might have overwritten their version, breaking their code that expects it to work their way. On the other hand, what if Rails loaded their version after yours? Then their code would work but your code would be mysteriously broken.

There are two problem with this 'safe' approach. The first is that it is tedious to write RewriteRails::ExtensionMethods::Enumerable.sum in place of plain "sum." The second is that [sometimes our code will be more readable when we use infix notation](http://weblog.raganwald.com/2008/01/no-detail-too-small.html "No Detail Too Small") (like instance method calls) instead of prefix notation (like class method calls). So what we want is to write:

    [[1,2], [3,4], [5,6]].sum
      => 21

In our code, but we do not want to break any code that relies on the other definition of Enumerable#sum. Well, you are reading the docs for RewriteRails, so you know the answer already: You want it such that every time we write:

    [[1,2], [3,4], [5,6]].sum

We want RewriteRails to rewrite our code as:

    RewriteRails::ExtensionMethods::Enumerable.sum([[1,2], [3,4], [5,6]])
    
Notice how the receiver of our fake instance method is transformed into the first parameter of our helper class method. And in fact, this is almost exactly what happens. So you get the readability of code that looks like it is defining an instance method on a core class or module, but you get the safety of actually using a new helper module that won't conflict with other people's mucking about.

**Major Caveat**

Rewrite has to know which extension methods you've defined *before it processes your .rr files*. In practice, this means you want to include an initializer file with contents similar to this:

    RewriteRails::ExtensionMethods::Enumerable

You want to force Rails to load each of your definitions before it processes your files, so you want one such lien for each class or module you have. Another way to do it is to put the entire body of the definition in an initializer, it's your choice.

**The Fine Print**

Here are a few considerations for those who want to "look under the hood." RewriteRails actually throws a little type discrimination into the rewritten code, so the actual rewritten code will look like this:

    __124040247470700__ = [[1,2], [3,4], [5,6]]
    if __124040247470700__.kind_of?(Enumerable)
      RewriteRails::ExtensionMethods::Enumerable.sum(__124040247470700__)
    else
      __124040247470700__.sum
    end

And if you write a #sum method on two different classes, the code will look something like this:

    __124040247470700__ = [[1,2], [3,4], [5,6]]
    if __124040247470700__.kind_of?(Enumerable)
      RewriteRails::ExtensionMethods::Enumerable.sum(__124040247470700__)
    elsif __124040247470700__.kind_of?(LegalArgument)
      RewriteRails::ExtensionMethods::LegalArgument.sum(__124040247470700__)
    else
      __124040247470700__.sum
    end

One obvious limitation of this approach is that it unexpected things will happen when you define the same method on two different modules included in one object, or on two different classes in the same inheritance hierarchy. When you need to handle complicated things like this, you really should use an actual method and live with any conflicts that arise: Extension methods are not intended to replace instance methods, merely provide a low-pain syntactic substitute for simple cases.

Another consideration is that the actual method we write is not a real instance method. So you can't access instance variables or private methods. Our helper methods are just that, helpers.

A third consideration is that this is just syntactic sugar. If we didn't have somebody else helpfully defining Enumerable#sum elsewhere, the following might surprise you:

    [[1,2], [3,4], [5,6]].respond_to?(:sum)
      => false
    [[1,2], [3,4], [5,6]].methods.include?('sum')
      => false
    [[1,2], [3,4], [5,6]].send(:sum)
      => NoMethodError
    [[1,2], [3,4], [5,6]].sum
      => 21

These things look like instance methods, but please remember they are nothing more than syntactic sugar that are transformed at run time into calls to our helper methods. If you are doing any kind of meta-programming, they are not going to work for you. If you need to define methods on your classes that might be called with Object#send or queried, they are not going to work for you.

Instead, use these to write simpler, easier to read code with fewer compatibility headaches. That's what they're for.

**This may work for Larry, but what about Curly and Moe?**

An [area man](http://blog.jcoglan.com/2009/04/02/april-fool-area-man-releases-worlds-slowest-scheme-interpreter/ "April fool: area man releases world&#8217;s slowest Scheme interpreter") asked:

> What if we all used rewrite_rails? You can still get two definitions for RewriteRails::ExtensionMethods::Enumerable.sum

Good catch! The long answer is that Rewrite Rails is specifically written to make it simple for Rails developers to insulate themselves from the vagaries of gem and plugin authors. So my first priority is protecting your code from ordinary Ruby metaprogramming conflicts.

That being said, I do have it in my mind that one day you will be able to use this technology to write gems that are likewise insulated from every other gem. That wasn't an immediate goal, so I initially left out some stuff that would add complexity to the implementation.

But since I was chided by a fellow kind enough to link to Rewrite Rails on his blog... *Steps have been taken*.

**Scoped Extension Methods**

In addition to `RewriteRails::ExtensionMethods`, you can place your extension methods somewhere in the parent hierarchy above the current class or module. Let me be specific. If you are writing `::Foo`, there is no parent and you must place all of your extension methods in `::RewriteRails::ExtensionMethods`. You can run into conflicts.

If you are writing `::Admin::LoginController`, you can place your extension methods in either `::RewriteRails::ExtensionMethods` or `::Admin::ExtensionMethods`.

If you *really love your lexical scope*, you might be writing `::Raganwald::TwitterTools::Admin::LoginController`. Now you can place your extension methods in `::RewriteRails::ExtensionMethods`, `::Raganwald::TwitterTools::Admin::ExtensionMethods`, `::Raganwald::TwitterTools::ExtensionMethods`, or `::Raganwald::ExtensionMethods` as you please.

It's up to you to use modules and classes to create scopes where you can place your extension methods. Note that you **cannot** place your extension methods in the current scope. The following will *not* work:

    class Foo
      module ExtensionMethods
        class Numeric
          def self.ata(depth_in_feet)
            depth_in_feet.to_f / 33.0 # FSW
          end
        end
      end
      
      def bar
        # ...
        depth.ata
        # ...
      end
      
    end
    
This won't work because `Foo::ExtensionMethods` is defined in `Foo`. In the current implementation, the reason for this is that the module containing your various extension method definitions must be available to the rewriter *before* it rewrites a file. It might be possible to fidjit with things such that `Foo::ExtensionMethods` is processed in one file and the body of `Foo` in another, but the current implementation will ignore `Foo::ExtensionMethods` when processing `Foo`, period.

However, go wild with:

    # lib/seawater/extension_methods/number.rb
    
    class Seawater::ExtensionMethods::Numeric
      def self.ata(depth)
        depth_in_feet.to_f / 33.0
      end
    end

    # lib/seawater/extension_methods/number.rb
    
    class Freshwater::ExtensionMethods::Numeric
      def self.ata(depth)
        depth_in_feet.to_f / 34.0
      end
    end

    # app/controllers/conversion_controller.rr
    
    class Seawater::ConversionController
    
      def show
        # ...
        @pressure = @depth.ata 
          # => something like Seawater::ExtensionMethods::Numeric.ata(@depth) 
        # ...
      end
      
    end

    # app/models/nitrox.rr
    
    class Freshwater::Nitrox
    
      def validate
        # ...
        @ppo2 = self.depth.ata * self.fo2
          # => something like Freshwater::ExtensionMethods::Numeric.ata(self.depth) * self.fo2
        # ...
      end
      
    end
    
    # config/initializers/extension_methods.rb
    
    Freshwater::ExtensionMethods::Numeric
    Seawater::ExtensionMethods::Numeric
    
Don't forget that like extension methods defined in `RewriteRails::ExtensionMethods`, you need to make sure that Rails loads them before processing your .rr files.

---

[RewriteRails](http://github.com/raganwald-deprecated/rewrite_rails/tree/master#readme)