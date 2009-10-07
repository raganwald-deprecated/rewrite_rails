Into
===

In [No Detail Too Small](http://weblog.raganwald.com/2008/01/no-detail-too-small.html), `Object#into` was defined as a Ruby method using monkey-patching:

    class Object
      def into expr = nil
        expr.nil? ? yield(self) : expr.to_proc.call(self)
      end
    end

If you are in the habit of violating the [Law of Demeter](http://en.wikipedia.org/wiki/Law_of_Demeter), you can use `#into` to make an expression read consistently from left to right. For example, this code:

    lambda { |x| x * x }.call((1..100).select(&:odd?).inject(&:+))
	
Reads "Square (take the numbers from 1 to 100, select the odd ones, and take the sum of those)." Confusing. Whereas with `#into`, you can write:

    (1..100).select(&:odd?).inject(&:+).into { |x| x * x }

Which reads "Take the numbers from 1 to 100, keep the odd ones, take the sum of those, and then answer the square of that number."

A permuting combinator like `#into` is not strictly necessary when you have parentheses or local variables. Which is kind of interesting, because it shows that if you have permuting combinators, you can model parentheses and local variables.

But we are not interested in theory. `#into` may be equivalent to what we can accomplish with other means, but it is useful to us if we feel it makes the code clearer and easier to understand. Sometimes a longer expression should be broken into multiple small expressions to make it easier to understand. Sometimes it can be reordered using tools like `#into`.

Rewriting `#into`
---

In [RewriteRails](http://github.com/raganwald/rewrite_rails "raganwald's rewrite_rails at master - GitHub"), `#into` is implemented with local assignment. So our example above:

    (1..100).select(&:odd?).inject(&:+).into { |x| x * x }
  
Is rewritten as:

    (x = (1..100).select(&:odd?).inject(&:+)
      (x * x))

(The newline is significant)

And yes, you can write:

    (1..100).select(&:odd?).inject(&:+).into(&'**2')

With *String to Block* and you will get:

    (_0 = (1..100).select(&:odd?).inject(&:+)
      (_0 ** 2))

`#into` plays well with others :-)

Limitations
---

The monkey-patching version also works with things that can be converted to procs with `#to_proc`. This version does not, because it is strictly syntactical.

---

[RewriteRails](http://github.com/raganwald/rewrite_rails/tree/master#readme)