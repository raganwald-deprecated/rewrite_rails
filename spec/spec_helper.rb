# ENV["RAILS_ENV"] = "test"
# require File.expand_path(File.join(RAILS_ROOT, 'config', "environment"))
require 'rubygems'
require 'spec' # despite the name, you need sudo gem install rspec
# require 'spec/rails' # and here, sudo gem install rspec-rails
Dir["#{File.dirname(__FILE__)}/helpers/*_helper.rb"].each do |helper|
   require helper
end

Dir["#{File.dirname(__FILE__)}/../lib/*.rb"].each do |r|
   require r
end

Dir["#{File.dirname(__FILE__)}/../lib/rewrite_rails/sexp_utilities.rb"].each do |r|
   require r
end

Dir["#{File.dirname(__FILE__)}/../lib/rewrite_rails/*.rb"].each do |r|
   require r
end

Dir["#{File.dirname(__FILE__)}/../lib/rewrite_rails/call_by_name/*.rb"].each do |r|
   require r
end

module Returning
  
  def returning(foo)
    yield foo if block_given?
    foo
  end
  
end    

unless :foo.respond_to?(:returning)
  Object.send(:include, Returning)
end

module ToProc
  
  def to_proc
    Proc.new { |*args| args.shift.__send__(self, *args) }
  end
  
end

unless :bar.respond_to?(:to_proc)
  Symbol.send(:include, ToProc)
end


Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb

  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  # 
  # For more information take a look at Spec::Example::Configuration and Spec::Runner
end
