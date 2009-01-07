The RewriteRails Plug-In
========================

RewriteRails adds syntactic abstractions like [Andand](http://github.com/raganwald/rewrite_rails/tree/master/doc/andand.textile "") and [String to Block](http://github.com/raganwald/rewrite_rails/tree/master/doc/string_to_block.md "") to Rails projects without monkey-patching. All of the power and convenience, none of the compatibility woes and head-aches.

Should You Care?
---

If you're already using gems like `Object#andand` or `String#to_proc`, RewriteRails is absolutely for you. You can continue to do what you're already doing, but your rails code will be faster and you will never have to worry about some gems conflicting with each other and with ActiveSupport as it grows.

If you have considered using `Object#andand` or `String#to_proc`, but hesitated because you are worried about encumbering classes like `Object` and `String` with even more methods, RewriteRails is for you. You get to use these powerful constructs without monkey-patching. You read that right. **RewriteRails is a No Monkey-Patching Zone**.

*If you want the power and convenience without the head-aches. RewriteRails is for you.*

Q & A
-----

**How does it work?**

Install the `RewriteRails` plugin in your Rails project and the gems ParseTree and Ruby2Ruby (in your system or frozen into your project). You can write ruby files as usual (e.g. `foo_bar.rb`), and things will work as usual. You can also have `RewriteRails` rewrite Ruby files for you. Any file with the suffix `.rr` will be "rewritten."

RewriteRails takes your `.rr` files and scans them with *rewriters*. Each rewriter looks for a certain kind of Ruby code and rewrites it into another kind of Ruby code. This produces the same effect as a C Preprocessor, a C++ template, or a Lisp Macro.

Currently, the rewriters are things that could be implemented by opening core classes and monkey-patching, but implementing them as rewriters means that you have higher performance and fewer conflicts with existing code.

By default, the rewritten files are stored in the `rewritten` directory of your project. So if you create a file called `foo.rr` in `lib` directory, you will find a file called `foo.rb` in `rewritten/lib`. This means you can always see what RewriteRails is doing, and if you want to stop using it you have 100% working Ruby files.

RewriteRails also tells Rails to look in the `rewritten` folder for your code, so you don't have to move anything around, it's as if Rails is reading your `.rr` files directly.

**So is a `.rr` file something like an erb or haml template?**

Yes. And also No. Yes, it is like a template in that it is turned into a `.rb` file that Rails executes. But no in that you won't find a bunch of special directives or any other trappings of a "template language." `.rr` files are Ruby files, they look like they use a bunch of monkey-patched extensions, but RewriteRails rewrites them so that they only use Standard Ruby.

If you would like a metaphor, imagine that you embrace syntactic abstractions like `#andand`, but you have a colleague who dislikes monkey-patching intensely, so much so that every time you write some code like:

    Product.find(:first, ...).andand.update_attribute(:on_sale, true)

Your colleague "fixes" it by rewriting it to:

    (first_product = Product.find(:first, ...) and first_product.update_attribute(:on_sale, true))

The good news is that while your colleague's rewriting destroys what you originally wrote, RewriteRails leaves your `.rr` files just the way it found them. So with RewriteRails, both you and your colleague can get along just fine.

**How do I know what will be rewritten?**

Consult [the doc folder](http://github.com/raganwald/rewrite_rails/tree/master/doc). Every rewriter gets its own page. At the moment, those are [Andand](http://github.com/raganwald/rewrite_rails/tree/master/doc/andand.textile "doc/andand.textile"), [Into](http://github.com/raganwald/rewrite_rails/tree/master/doc/into.md) and [String to Block](http://github.com/raganwald/rewrite_rails/tree/master/doc/string_to_block.md "doc/string_to_block.md"). More will be added as I write them or port them from the old rewrite gem.

**How can I see what is rewritten?**

After you write a `.rr` file, you can run your code in the normal way: `script/console`, `script/server`, or best of all `rake test` :-)

As mentioned, RewriteRails will place a `.rb` in the `rewritten` directory for each of your `.rr` files and you can open them up in a text editor. Like any generated file, you should not edit the rewritten files.

**My colleagues don't mind me writing .rr files, but they prefer .rb files. What do we do?**

RewriteRails its generated `.rb` files in its own `rewritten` directory, and ignores `.rb` files in Rails' standard directories. So if your team prefers to have some `.rb` files and some `.rr` files, you know that the `.rb` files in Rails' standard directories are all ok to edit as you see fit.

In other words, you can write `.rb` files whenever you want and as long as they are in Rails' standard directories, they will behave exactly as you expect. You can mix `.rb` and `.rr` files as much as you like.

**I like this for development, but I don't want to install all those gems on my server**

1. Run `rake rewrite:prepare`. This will recursively rewrite all of the `.rr` files in your project so that it is not necessary to run them in production.
2. Do not install the RewriteRails plugin on your server.
3. Open up `config/environments/production.rb` and add the following lines
  * `config.load_paths += %W( #{RAILS_ROOT}/rewritten/app/controllers )`
  * `config.load_paths += %W( #{RAILS_ROOT}/rewritten/app/helpers )`
  * `config.load_paths += %W( #{RAILS_ROOT}/rewritten/app/models )`
  * `config.load_paths += %W( #{RAILS_ROOT}/rewritten/app/lib )`
  * ...and any other directories where you might place `.rr` files

Now when you run your project in production, the `.rr` files will not be rewritten on the fly, but Rails will continue to find the rewritten `.rb` files in the `rewritten` directory. You don't have to do anything else, you won't need ParseTree, Ruby2Ruby, or RewriteRails on your production servers.

**How does this differ from the rewrite gem?**

Where the rewrite gem allows you to rewrite specific blocks of code and to treat rewriters as first-class entities for meta-meta-programming, `RewriteRails` simply rewrites entire files with a known set of rewriters.

**Why is this better than the rewrite gem?**

First, it's better for you tomorrow. If in the distant future there is some problem that breaks Rewrite (like changes to its dependencies or to MRI), you have your .rb files intact and working.

Second, it's better for you today. If someone else goes wild with Mnkey-patching, it won't break any of your rewritten code.

**There must be some reason to prefer rewriting on the fly instead of rewriting files!**

Well, if you love abstractions the Rewrite gem treats rewriters as first-class entities and lets you programatically apply them to individual blocks of code at run time. If you can think of a reason why you need that functionality, please get in touch, I'd like to understand the use case.

**Do I have to run any rake tasks?**

No, RewriteRails rewrites your `.rr` files on the fly. However, you may wish to run `rake rewrite:prepare` whenevr you wish to inspect what the resulting code will look like without running it. It also might be a nice ides to run it before checking code in, just to be 100% sure your repository has a complete set of the latest `.rb` files.

**That was fun, but we hired a new architect who has decided make his mark by criticizing all of our decisions and insists we stop all new development while we migrate RewriteRails out of our million line project. Are we fuxxored?**

Adding a new smartest guy in the room might fuxxor your project for other reasons, but your code is safe with RewriteRails.

Run:

  rake rewrite:all rewritten=.
  
This does the `prepare` task that rewrites all of your code, but instead of placing the resulting `.rb` files in a hierarchy in the `rewritten` folder, it places them in your project right next to the `.rr` files. You can now remove the RewriteRails plugin and your project will work just as if you had never used it. (Removing the out-dated `.rr` files from the command line shouldn't be a problem for anyone who values removing technical debt enough to stop all new development.)

The summary is that you can experiment with `RewriteRails` as much as you like, but you are not painting yourself into a corner. You can escape to standard Ruby at any time. In fact, RewriteRail is all about Standard Ruby. The whole point of the plugin is to always maintain your code using Standard Ruby, it's just that RewriteRails lets you use powerful idioms to write standard ruby code.

Installation and Dependencies
------------

1. `sudo gem install ParseTree`
2. `sudo gem install ruby2ruby`
3. Clone this project into the `vendor/plugins` directory of your project.

Legal
-----

Copyright (c) 2008 Reginald Braithwaite, released under the [MIT license](http:MIT-LICENSE).
