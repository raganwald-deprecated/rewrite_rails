The RewriteRails Plug-In
========================

This is an experiment in performing global rewriting for Rails projects. 

Should Care You Care?
---

My personal message to you:

> I am a firm believer that I am only responsible for "Making One Sale." There are a number of questions you need to answer for yourself:

> First, do you consider opening core classes like `Object` and `String` to be a problem? Second, do you want syntactic abstractions like `#andand`, `#try`, or `Symbol#to_proc` in your project? And third, if you want to use them and you consider opening core classes to be a problem, is `RewriteRails` the best solution to the problem?

> I can only answer ONE of those questions for you at a time. We aren't going to get anywhere if I am explaining why opening core classes is a problem while you are thinking that what you really need is a way to federate your application across the cloud, not a way to simplify the expression `MyModel.find(:all, ...).map { |model| model.name }`. Likewise, if you dislike `foo.try(:bar)`, what is the point of discussing the difference between implementing `#try` as syntax rather than as a method?

> Therefore, I am assuming that you have already embraced the idea that the proliferation of additions to core classes like `Object` and `String` is unsustainable. This explanation assumes that you have embraced syntactic abstractions such as `#andand` and `Symbol#to_proc`, but are looking for a way to use existing abstractions or add new ones without opening core classes.

> If you are perfectly happy with the unrestricted growth of core classes and/or see no need for syntactic abstractions, my opinion is that this plug-in is not for your project at this time.

Q & A
-----

*	**How does it work?**

Install the `RewriteRails` plugin and all of its dependancies. You can write ruby files as usual (e.g. `foo_bar.rb`), and things will work as usual. You can also have `RewritRails` rewrite your files for you. Anything with the suffix `.rr` will be rewritten.

*	**Clear as mud. What does it mean to "rewrite" a file?**

Certain idioms are recognized as macros and rewritten when the file is first loaded. The canonical example is that:

	foo.andand.map(&:bar)

Will be rewritten as:

	(foo and foo.map(&:bar))
	
And:

	FooModel.find(:first, ...).andand.bar

Will be rewritten as:

	(__123456789__ = FooModel.find(:all, ...) and __123456789__.bar)

This way, rewriting can be added to an existing project without breaking existing code. You can even have some files use the existing `andand` while new code uses the rewriting version.

*	**How do I know what will be rewritten?**

That will be documented. Eventually.

*	**How can I see what the result looks like?**

By default, the rewritten files are stored in the `rewritten` directory of your project.

*	**I don't want to install all those gems on my server**

This is not finished yet, but it is a work in progress:

1. Run `rake rewrite:prepare`. This will recursively rewrite all of the `.rr` files in your project so that it is not necessary to run them in production.
2. TODO: A configuration option that will ignore `.rr` options at run time for certain named environments, something like a controller filter.

*	**How does this differ from the rewrite gem?**

Where the rewrite gem allows you to rewrite specific blocks of code and to treat rewriters as first-class entities for meta-meta-programming, `RewriteRails` simply rewrites entire files with a known set of rewriters.

*	**That was fun, but we hired a new architect who has decided make his mark by criticizing all of our decisions and insists we stop all new development while we migrate it out of our million line project. Are we fuxxored?**

Your new smartest guy in the room might be fuxxored, but your code is safe. Simply run `rake rewrite:prepare rewritten=.` This does the `prepare` task that rewrites all of your code in place, but instead of placing the resulting `.rb` files in a hierarchy in the `rewritten` folder, it places them all in a hierarchy in the root of your project. Which means, they go right next to the .rr files. You can now remove the rewrite plugin and carry on. Removing the out-dated `.rr` files from the command line shouldn't be a problem for your new smart fellow.

The summary is that you can experiment with `RewriteRails` as much as you like, but you are not painting yourself into a corner. You can escape to standard Ruby at any time.

Installation
------------

It isn't ready yet, but when it is, you will simply clone it into your `vendor/plugins` directory.

Legal
-----

Copyright (c) 2008 Reginald Braithwaite, released under the [MIT license](http:MIT-LICENSE).
