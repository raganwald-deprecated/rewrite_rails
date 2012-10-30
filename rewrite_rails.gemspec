Gem::Specification.new do |s|
  s.name     = "rewrite_rails"
  s.version  = "2009.01.06"
  s.date     = "2009-01-06"
  s.summary  = "Code rewriting for Ruby on Rails projects"
  s.email    = "reg@braythwayt.com"
  s.homepage = "hhttp://github.com/raganwald-deprecated/rewrite_rails/tree/master"
  s.description = " Code rewriting for Ruby on Rails projects."
  s.has_rdoc = false
  s.authors  = ["Reg Braithwaite"]
  s.files    = ["init.rb",
"MIT-LICENSE",
"Rakefile",
"README.md",
"lib/rewrite_rails.rb",
"lib/andand.rb",
"lib/string_to_block.rb",
"tasks/rewrite.rake"]
  s.test_files = [
"spec/andand_spec.rb",
"spec/spec_helper.rb",
"spec/string-to_block_spec.rb"]
end