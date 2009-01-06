String to Block
===

*String to Block* is a port of the String Lambdas from Oliver Steele's [Functional Javascript](http://osteele.com/sources/javascript/functional/ "Functional Javascript") library. I have modified the syntax to hew closer to Ruby's idioms.

*String to Block* is based on [String#to\_proc](http://github.com/raganwald/homoiconic/tree/master/2008-11-28/you_cant_be_serious.md "You can't be serious!?"). The difference is that *String to Block* accomplishes its magic by opening up `String` and adding a `to_proc` method, then calling that method twice every time you write something like:

    (1..100).map(&'1..n').inject(&'+')

*String to Block* does something entirely different. It rewrites `(1..100).map(&'1.._').map(&'+')` as:

    (1..num).map { |_| (1.._) }.inject { |_0, _1| (_0 + _1) }

This is obviously much faster at run time and more importantly, does not cause a conflict if somewhere else in your application you write your own `to_proc` method for `String`. And when I say "you," I mean *you and the authors of every gem and plugin you use*. For example, [Sami Samhuri](http://sami.samhuri.net/2007/5/11/enumerable-pluck-and-string-to_proc-for-ruby/ "Enumerable#pluck and String#to_proc for Ruby").

gives
---

First, *String to Block* provides several key abbreviations: First,	`->` syntax for blocks in Ruby 1.8. So instead of `(1..100).inject { |x,y| x + y }`, you can write `(1..100).inject(&'x,y -> x + y')`. I read this out loud as "*x and y gives x plus y*."If the `->` seems foreign, it is only because `->` is in keeping with modern functional languages and mathematical notation.

Gives isn't a particularly big deal considering how easy it is to write an old-fashioned block, it's a lot more handy when doing really functional things. But it's included so that you can make code that's aristocratic.

inferred parameters
---

Second, *String to Block* adds inferred parameters: If you do not use `->`, *String to Block* attempts to infer the parameters. So if you write `'x + y'`, *String to Block* rewrites it as `{ |x,y| x + y }`. There are certain expressions where this doesn't work, and you have to use `->`, but for really simple cases it works just fine. And frankly, for really simple cases you don't need the extra scaffolding.

Here're some examples using inferred parameters:

    foo.select(&'x.kind_of?(Numeric)')
      => foo.select { |x| x.kind_of?(Numeric) }
	  
    bar.map(&'x ** 2')
      => bar.map { |x| x ** 2 }

> I have good news and bad news about inferred parameters and *String to Block* in general. It uses regular expressions to do its thing, which means that complicated things often don't work. For example, nesting `->` only works when writing functions that return functions. So `'x -> y -> x + y'` is a function that takes an `x` and returns a function that takes a `y` and returns `x + y`. That works. But `'z -> z.inject(&"sum, n -> sum + n")'` does NOT work.

> I considered fixing this with more sophisticated parsing, however the simple truth is this: *String to Block* is not a replacement for blocks, it's a tool to be used when what you're doing is so simple that a block is overkill. If *String to Block* doesn't work for something, it probably isn't ridiculously simple any more.

it
---

The third abbreviation is a special case. If there is only one parameter, you can use `_` (the underscore) without naming it. This is often called the "hole" or pronounced "it." If you use "it," then *String to Block* doesn't try to infer any more parameters, so this can help you write things like:

    foo.select(&'_')
      => foo.select { |_| _ }
	  
    bar.map(&'_.inject { |sum, n| sum + n }')
      => bar.map { |_| _.inject { |sum, n| sum + n } }

Admittedly, use of "it"/the hole is very much a matter of taste.

point-free
---

*String to Block* has a fourth and even more extreme abbreviation up its sleeve, [point-free style](http://blog.plover.com/prog/haskell/ "The Universe of Discourse : Note on point-free programming style"): "Function points" are what functional programmers usually call parameters. Point-free style consists of describing how functions are composed together rather than describing what happens with their arguments. So, let's say that I want a function that combines `.inject` with `+`. One way to say that is to say that I want a new function that takes its argument and applies an `inject` to it, and the inject takes another function with two arguments and applies a `+` to them:

    foo.map { |z| z.inject { |sum, n| sum + n } }
	
The other way is to say that I want to compose `.inject` and `+` together. Without getting into a `compose` function like Haskell's `.` operator, *String to Block* has enough magic to let us write the above as:

    foo.map(&".inject(&'+')")
      => foo.map { |_0| _0.inject { |_0, _1| _0 + _1 } }
	
Meaning "*I want a block that does an inject using plus*." Point-free style does require a new way of thinking about some things, but it is a clear win for simple cases. Proof positive of this is the fact that Ruby on Rails and Ruby 1.9 have both embraced point-free style with `Symbol#to_proc`. That's exactly how [`(1..100).inject(&:+)`](http://weblog.raganwald.com/2008/02/1100inject.html "(1..100).inject(&:+)") works!

*String to Block* supports fairly simple cases where you are sending a message or using a binary operator. So if we wanted to go all out, we could write things like:

    foo.reject(&'.kind_of?(Numeric)')
      => foo.reject { |_0| _0.kind_of?(Numeric) }
      
    bar.map(&'** 2')
      => bar.map { |_0| _0 ** 2 }
      
    blitzes.map(&".inject(&'+')")
      => blitzes.map { |_0| _0.inject { |_0, _1| _0 + _1 } }

> There's no point-free magic for the identity function, although this example tempts me to special case the empty string!

Blocks not Procs
---

Unlike `String#to_proc`, *String to Block* is strictly for blcoks. If you want a lambda, write `lambda(&'x,y -> x + y')`.

When should we use all these tricks?
---

*String to Block* provides these options so that you as a programmer can choose your level of ceremony around writing functions. But of course, you have to use the tool wisely. My *personal* rules of thumb are:

1.	Embrace inferred parameters for well-known mathematical or logical operations. For these operations, descriptive parameter names are usually superfluous. Follow the well-known standard and use `x`, `y`, `z`, and `w`;  or `a`, `b` and `c`; or `n`, `i`, `j`, and `k` for the parameters. If whatever it is makes no sense using those variable names, don't used inferred parameters.
1.	Embrace the hole for extremely simple one-parameter lambdas that aren't intrinsically mathematical or logical such as methods that use `.method_name` and for the identity function.
1.	Embrace point-free style for methods that look like operators.
1.	Embrace `->` notation for extremely simple cases where I want to give the parameters a descriptive name.
1.	Use ordinary Ruby blocks for everything else.