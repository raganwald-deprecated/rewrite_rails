Issues with RewriteRails
===

**Erb and Haml templates**

At this time I haven't figured out how to make rewriting work in erb or haml templates. I think the template engine itself has to be hooked rather than working with the files.

**file paths**

Because `rewrite_rails` makes copies of your `.rr` files and puts them in a new place, this will wreak havoc with relative paths in your code. Most specifically, when you manually `require` another file, you can have unexpected errors, especially if you use relative paths. For example, `test_helper.rb` might be in the same directory as `foobar_test.rb`, but if you write `widget_test.rr`, you will discover that the `widget_test.rb` file created by `rewrite_rails` is off in an entirely different directory and a relative link will break.

**rake test**

Test files are funny. They don't use Rails' automagical loading, so `rewrite_rails` doesn't intercept them. Therefore... You cannot use rewriters on test cases at this time.