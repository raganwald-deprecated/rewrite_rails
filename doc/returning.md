Returning
===

The [RewriteRails](http://github.com/raganwald/rewrite_rails/tree/master) plug-in now includes its own version of #returning that overrides the #returning shipping with ActiveSupport :-o

When RewriteRails is processing source code, it turns code like this:

    def registered_person(params = {})
      returning Person.new(params.merge(:registered => true)) do |person|
        if Registry.register(person)
          person.send_email_notification
        else
          person = Person.new(:default => true)
        end
      end
    end
    
Into this:

    def registered_person(params = {})
      lambda do |person|
        if Registry.register(person)
          person.send_email_notification
        else
          person = Person.new(:default => true)
        end
        person
      end.call(Person.new(params.merge(:registered => true)))
    end

Note that in addition to turning the #returning "call" into a lambda that is invoked immediately, it also makes sure the new lambda returns the `person` variable's contents. So assignment to the variable does change what #returning appears to return.

There's more about the motivation for returning the variable's contents in my post [Rewriting Returning in Rails](http://github.com/raganwald/homoiconic/blob/master/2009-08-29/returning.md#readme "").

Like all processors in RewriteRails, #returning is only rewritten in `.rr` files. Existing `.rb` files are not affected, including all code in the Rails framework, so it will never monkey with other people's expectations. #returning can also be disabled for a project if you don't care for it.

**More**

* [returning.rb](http://github.com/raganwald/rewrite_rails/tree/master/lib/rewrite_rails/returning.rb "")
* [Rewriting Returning in Rails](http://github.com/raganwald/homoiconic/blob/master/2009-08-29/returning.md#readme "")

---

[RewriteRails](http://github.com/raganwald/rewrite_rails/tree/master#readme)