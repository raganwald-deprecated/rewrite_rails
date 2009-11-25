require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))

puts RewriteRails.clean {
  def foo(bar)
    blitz = bar = nil
    bar()
    blitz
    buddicombe
  end
}.inspect