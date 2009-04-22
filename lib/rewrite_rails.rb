require 'pp'
begin require 'rubygems' rescue LoadError end
require 'parse_tree'
require 'sexp'
require 'sexp_processor'
require 'unified_ruby'
require 'ruby2ruby'
require 'ftools'
require 'parse_tree_extensions'

class Unifier
  include UnifiedRuby
end

module RewriteRails
  
  NEWLINE_NODES = false
  
  class PersistingCallByNameProcessor < CallByName::ClassProcessor
    
    def initialize
      was_methods = self.methods_converted_on_creation
      super
      if was_methods != self.methods_converted_on_creation
        RewriteRails.write_module(RewriteRails::CallByName)
        
        p_rb = File.read(File.join(File.dirname(__FILE__), 'rewrite_rails', 'call_by_name', 'p.rb'))
        p_path = File.join(RewriteRails.cache_folder_path, 'lib', 'rewrite_rails', 'call_by_name', 'p.rb')
        File.makedirs(File.dirname(p_path))
        File.open(p_path, 'w') do |f|
          f.write(p_rb)
        end
        
      end
    end
    
  end
  
  def self.from_sexp(sexp)
    [
      Andand, 
      StringToBlock, 
      Into,
      PersistingCallByNameProcessor,
      ExtensionProcessor
    ].inject(sexp) do |acc, rewrite_class|
      eval(rewrite_class.new.process(acc).to_s)
    end
  end

  def self.cache_folder_name=(name)
    @cache_folder_name = name
  end
  
  def self.cache_folder_name
    @cache_folder_name ||= ENV['rewritten'] || 'rewritten'
  end
  
  def self.cache_folder_path
    File.expand_path(File.join(RAILS_ROOT, cache_folder_name()))
  end
  
  def self.hook_the_hook!
    
    ActiveSupport::Dependencies.class_eval do

      def search_for_file_with_rewriting(path_suffix)
        unless path_suffix =~ /\.rb$/
          rr_path_suffix = path_suffix =~ /\.rr$/? path_suffix : path_suffix + '.rr'
          load_paths.each do |root|
            rr_path = File.expand_path(File.join(root, rr_path_suffix))
            if File.file?(rr_path)
              RewriteRails.rewrite_file(rr_path)
            end
          end
        end
        search_for_file_without_rewriting(path_suffix)
      end

      alias_method_chain :search_for_file, :rewriting

    end
    
    ActiveSupport::Dependencies.load_paths.dup.each do |existing_load_path|
      expanded_path = File.expand_path(existing_load_path)
      if expanded_path.start_with? expanded_rails_root()
        rewritten_path = File.expand_path(File.join(cache_folder_path(), expanded_path[expanded_rails_root().length..-1]))
        ActiveSupport::Dependencies.load_paths << rewritten_path
      end
    end
    
  end  

  PARSER = ParseTree.new(NEWLINE_NODES)
  UNIFIER = Unifier.new
    
  def self.rewrite_file(rr_path)
    root = File.dirname(rr_path)
    rb_path = target_path("#{rr_path[/^(.*)\.rr$/,1]}.rb")
    File.makedirs(File.dirname(rb_path))
    rr = File.read(rr_path)
    raw_sexp = PARSER.parse_tree_for_string(rr, rr_path).first
    rewritten_sexp = rewrite_sexp(raw_sexp)
    rewritten_sexp = eval(rewritten_sexp.to_s) # i STILL don't know why i need this!!
    rb = Ruby2Ruby.new.process(rewritten_sexp)
    File.open(rb_path, 'w') do |f|
      f.write(rb)
    end
  end
    
  # Very fragile!
  def self.write_module(module_to_write, destination = File.join(cache_folder_path, 'lib'))
    rb_path = File.join(destination, File.join(module_to_write.name.split('::').map { |f| f.underscore }) + '.rb')
    File.makedirs(File.dirname(rb_path))
    rb = Ruby2Ruby.translate(module_to_write)
    File.open(rb_path, 'w') do |f|
      f.write(rb)
    end
  end
  
  def self.clean(sexp = nil, &block)
    sexp ||= sexp_for(&block)
    sexp = Sexp.from_array(sexp)
    str = sexp.to_s
    UNIFIER.process(sexp) rescue eval(str)
  end
  
  def self.rewrite_sexp(sexp)
    sexp = from_sexp(clean(sexp))
  end
  
  def self.to_ruby(sexp = nil, &block)
    rewritten_sexp = rewrite_sexp(clean(sexp, &block))
    rewritten_sexp = eval(rewritten_sexp.to_s) # i STILL don't know why i need this!!
    rb = Ruby2Ruby.new.process(rewritten_sexp)
  end
  
  def self.expanded_rails_root
    @expanded_rails_root ||= File.expand_path(RAILS_ROOT)
  end
  
  def self.target_path(path)
    path = File.expand_path(path)
    raise ArgumentError unless path.start_with?(expanded_rails_root())
    partial_path = path[expanded_rails_root().length..-1]
    File.expand_path(File.join(cache_folder_path(), partial_path))
  end
  
  #s(:iter, s(:call, nil, :proc, s(:arglist)), s(:lasgn, :foo), s(:lit, :foo))
  def self.arguments(sexp)
    raise ArgumentError unless sexp[0] == :iter
    arguments = sexp[2]
    variable_symbols = if arguments[0] == :dasgn || arguments[0] == :dasgn_curr || arguments[0] == :lasgn
      [arguments[1]]
    elsif arguments[0] == :masgn
      arguments[1][1..-1].map { |pair| pair[1] }
    else
      raise "don't know how to extract paramater names from #{arguments}"
    end
  end
    
  class << self
    
    def default_generator
      lambda { :"__#{Time.now.to_i}#{rand(100000)}__" }
    end
    
    def gensym
      (@generator ||= default_generator).call()
    end
      
    def define_gensym(&block)
      @generator = block
    end
      
  end

  # Convert an expression to a sexp by taking a block and stripping
  # the outer proc from it.
=begin
s(:iter,
  s(:call, nil, :proc, s(:arglist)),
  nil, 
  s(:call, s(:call, nil, :foo, s(:arglist)), :bar, s(:arglist))
)
=end
  def self.sexp_for &proc
    sexp = proc.to_sexp
    raise ArgumentError if sexp.length != 4
    raise ArgumentError if sexp[0] != :iter
    raise ArgumentError unless sexp[2].nil?
    sexp[3]
  end

  # Convert an expression to a sexp and then the sexp to an array.
  # Useful for tests where you want to compare results.
  def self.arr_for &proc
    sexp_for(&proc).to_a
  end

  # Convert an object of some type to a sexp, very useful when you have a sexp
  # expressed as a tree of arrays.
  def self.recursive_s(node)
    if node.is_a? Array
      s(*(node.map { |subnode| recursive_s(subnode) }))
    else
      node
    end
  end
  
  def self.dup_s(sexp)
    recursive_s(sexp.to_a)
  end
  
end