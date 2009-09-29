Block Anaphora
===

In the post [Anaphora in Ruby](http://github.com/raganwald/homoiconic/blob/master/2009-09-22/anaphora.md#readme ""), I mentioned that [String#to\_block](http:string_to_block.md) supports a useful abbreviation. When writing a block that takes just one parameter, you can use either `it` or `its` without declaring the parameter (for backwards compatibility with String#to\_block you can also use an underscore, `_`).

For short messages, it is nearly as brief as Symbol#to\_proc:

    Person.all(...).map { its.first_name } # vs. Person.all(...).map( &:first_name )
    
Unlike Symbol#to\_proc, you can supply parameters:

    Person.all(...).map { it.reload(true) }

Or chain methods:

    Person.all(...).map { its.first_name.titlecase }
    
It needn't be the receiver either:

    Person.all(...).each { (name_count[its.first_name] ||= 0) += 1 }
	  
It works best when you would naturally use the word "it" or the possessive "its" if you were reading the code aloud to a colleague. So if you would say "For each person record, increment the count of its first name," the last example is fine.