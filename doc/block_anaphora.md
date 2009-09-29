Block Anaphora
===

When writing a block that takes just one parameter, you can use either `it` or `its` as a parameter without actually declaring the parameter using `{ |it| ... }`. This is a win whenever the purpose of the block and the parameter is obvious, for example:

    Person.all(...).map { its.first_name }

Writing:

    Person.all(...).map { |its| its.first_name }
    
Just adds clutter. This example is the same use case as Symbol#to\_proc:

    Person.all(...).map(&:first_name)
    
However, block anaphora go further. Unlike Symbol#to\_proc, you can supply parameters:

    User.all(...).each { it.increment(:visits) }

Or chain methods:

    Person.all(...).map { its.first_name.titlecase }
    
It needn't be the receiver either:

    Person.all(...).each { (name_count[its.first_name] ||= 0) += 1 }
	  
It works best when you would naturally use the word "it" or the possessive "its" if you were reading the code aloud to a colleague. And one more thing: You can use the underscore, `_` instead of `it` or `its`. This is for backwards compatibility with String#to\_block.

**more**

The post [Anaphora in Ruby](http://github.com/raganwald/homoiconic/blob/master/2009-09-22/anaphora.md#readme "") discusses block anaphora.