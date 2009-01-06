The RewriteRails Plug-In
========================

RewriteRails adds syntactic abstractions like [Andand](http://github.com/raganwald/rewrite_rails/tree/master/doc/andand.textile "") and [String to Block](http://github.com/raganwald/rewrite_rails/tree/master/doc/string_to_block.md "") to Rails projects without monkey-patching. All of the power and convenience, none of the compatibility woes and head-aches.

Should You Care?
---

I am a firm believer that I am only responsible for "Making One Sale." There are a number of questions you need to answer for yourself:

First, do you consider opening core classes like `Object` and `String` to be a problem? Second, do you want syntactic abstractions like `#andand`, `#try`, or `Symbol#to_proc` in your project? And third, if you want to use them and you consider opening core classes to be a problem, is `RewriteRails` the best solution to the problem?

I can only answer ONE of those questions for you at a time. We aren't going to get anywhere if I am explaining why opening core classes is a problem while you are thinking that what you really need is a way to federate your application across the cloud, not a way to simplify the expression `MyModel.find(:all, ...).map { |model| model.name }`. Likewise, if you dislike `foo.try(:bar)`, what is the point of discussing the difference between implementing `#try` as syntax rather than as a method?

Therefore, I am assuming that you have already embraced the idea that the proliferation of additions to core classes like `Object` and `String` is unsustainable. This explanation assumes that you have embraced syntactic abstractions such as `#andand` and `Symbol#to_proc`, but are looking for a way to use existing abstractions or add new ones without opening core classes.

If you are perfectly happy with the unrestricted growth of core classes and/or see no need for syntactic abstractions, my opinion is that this plug-in is not for your project at this time. However...

If you want the power and convenience without the head-aches. RewriteRails is for you.

Q & A
-----

**How does it work?**

Install the `RewriteRails` plugin in your Rails project and the gems ParseTree and Ruby2Ruby (in your system or frozen into your project). You can write ruby files as usual (e.g. `foo_bar.rb`), and things will work as usual. You can also have `RewriteRails` rewrite Ruby files for you. Any file with the suffix `.rr` will be "rewritten."

RewriteRails takes your `.rr` files and scans them with *rewriters*. Each rewriter looks for a certain kind of Ruby code and rewrites it into another kind of Ruby code. This produces the same effect as a C Preprocessor, a C++ template, or a Lisp Macro.

Currently, the rewriters are things that could be implemented by opening core classes and performing metaprogramming wizardry, but implementing them as rewriters means that you have higher performance and fewer conflicts with existing code.

By default, the rewritten files are stored in the `rewritten` directory of your project. So if you create a file called `foo.rr` in `lib` directory, you will find a file called `foo.rb` in `rewritten/lib`. This means you can always see what RewriteRails is doing, and if you want to stop using it you have 100% working Ruby files.

**How do I know what will be rewritten?**

Consult [the doc folder](http://github.com/raganwald/rewrite_rails/tree/master/doc). Every rewriter gets its own page. At the moment, those are [Andand](http://github.com/raganwald/rewrite_rails/tree/master/doc/andand.textile "doc/andand.textile") and [String to Block](http://github.com/raganwald/rewrite_rails/tree/master/doc/string_to_block.md "doc/string_to_block.md"). More will be added as I write them or port them from the old rewrite gem.

**I like this for development, but I don't want to install all those gems on my server**

1. Run `rake rewrite:prepare`. This will recursively rewrite all of the `.rr` files in your project so that it is not necessary to run them in production.
2. Do not install the RewriteRails plugin on your server.
3. Open up `config/environments/production.rb` and add the following lines
  * `config.load_paths += %W( #{RAILS_ROOT}/rewritten/app/controllers )`
  * `config.load_paths += %W( #{RAILS_ROOT}/rewritten/app/helpers )`
  * `config.load_paths += %W( #{RAILS_ROOT}/rewritten/app/models )`
  * `config.load_paths += %W( #{RAILS_ROOT}/rewritten/app/lib )`
  * ...and any other directories where you might place `.rr` files

Now in production files will not be rewritten but Rails will automatically load the rewritten files fromt he `rewritten` directory. (TODO: Automate this.) 

**How does this differ from the rewrite gem?**

Where the rewrite gem allows you to rewrite specific blocks of code and to treat rewriters as first-class entities for meta-meta-programming, `RewriteRails` simply rewrites entire files with a known set of rewriters.

**That was fun, but we hired a new architect who has decided make his mark by criticizing all of our decisions and insists we stop all new development while we migrate it out of our million line project. Are we fuxxored?**

Your new smartest guy in the room might be fuxxored, but your code is safe. Simply run `rake rewrite:all rewritten=.` This does the `prepare` task that rewrites all of your code in place, but instead of placing the resulting `.rb` files in a hierarchy in the `rewritten` folder, it places them all in a hierarchy in the root of your project. Which means, they go right next to the .rr files. You can now remove the rewrite plugin and carry on. Removing the out-dated `.rr` files from the command line shouldn't be a problem for your new smart fellow.

The summary is that you can experiment with `RewriteRails` as much as you like, but you are not painting yourself into a corner. You can escape to standard Ruby at any time.

Installation and Dependencies
------------

1. `sudo gem install ParseTree`
2. `sudo gem install ruby2ruby`
3. Clone this project into the `vendor/plugins` directory of your project.

Legal
-----

Copyright (c) 2008 Reginald Braithwaite, released under the [MIT license](http:MIT-LICENSE).
