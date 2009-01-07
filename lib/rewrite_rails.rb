require 'pp'
begin require 'rubygems' rescue LoadError end
require 'parse_tree'
require 'sexp'
require 'sexp_processor'
require 'unified_ruby'
require 'ruby2ruby'
require 'ftools'

class Unifier
  include UnifiedRuby
end

module RewriteRails

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

  PARSER = ParseTree.new(false) # no newline nodes
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
  
  def self.clean(sexp = nil, &block)
    sexp ||= Rewrite.sexp_for(&block)
    sexp = Sexp.from_array(sexp)
    str = sexp.to_s
    UNIFIER.process(sexp) rescue eval(str)
  end
  
  def self.rewrite_sexp(sexp)
    sexp = Rewrite.from_sexp(clean(sexp))
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
  
end