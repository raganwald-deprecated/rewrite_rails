The RewriteRails Plug-In
========================

This is an experiment in performing global rewriting for Rails projects. 

Why You Should Care
---

As a project grows in code as well as in dependencies on gems and plugins, the likelihood of conflicts increases. Features implemented with rewriting do not have global scope, and therefore do not create conflicts. You can add functionality without adding complexity.

Q & A
-----

*	**How does it work?**

Install the `RewriteRails` plugin and all of its dependancies. You can write ruby files as usual (e.g. `foo_bar.rb`), and things will work as usual. You can also have `RewritRails` rewrite your files for you. Anything with the suffix `.rr` will be rewritten.

*	**Clear as mud. What does it mean to "rewrite" a file?**

Certain idioms are recognized as macros and rewritten when the file is first loaded. The canonical example is that:

	foo.andand.map(&:bar)

Will be rewritten as:

	foo && foo.map(&:bar)
	
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

Thanks for reminding me. TODO: A rake task to recursively rewrite everything, plus a way to turn rewriting off in production.

*	**How does this differ from the rewrite gem?**

Where the rewrite gem allows you to rewrite specific blocks of code and to treat rewriters as first-class entities for meta-meta-programming, `RewriteRails` simply rewrites entire files with a known set of rewriters.

Installation
------------

It isn't ready yet, but when it is, you will simply clone it into your `vendor/plugins` directory.

Legal
-----

Copyright (c) 2008 Reginald Braithwaite, released under the [MIT license](http:MIT-LICENSE).
