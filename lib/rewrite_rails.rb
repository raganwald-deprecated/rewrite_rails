require 'pp'
begin require 'rubygems' rescue LoadError end
require 'parse_tree'
require 'sexp'
require 'sexp_processor'
require 'unified_ruby'
require 'ruby2ruby'

module RewriteRails
  
  def self.hook_the_hook!
    
    ActiveSupport::Dependencies.class_eval do

      def search_for_file_with_rewriting(path_suffix)
        unless path_suffix =~ /\.rb$/
          rr_path_suffix = path_suffix =~ /\.rr$/? path_suffix : path_suffix + '.rr'
          # could easily be expressed as map/select
          load_paths.each do |root|
            path = File.join(root, rr_path_suffix)
            if File.file?(path)
              RewriteRails.rewrite_file(path)
            end
          end
        end
        search_for_file_without_rewriting(path_suffix)
      end

      alias_method_chain :search_for_file, :rewriting

    end
    
  end  

  PARSER = ParseTree.new(false) # no newline nodes
    
  def self.rewrite_file(path)
    if File.file?(path)
      target_path = "#{path[/^(.*)\.rr$/,1]}.rb"
      rr = File.read(path)
      sexp = PARSER.parse_tree_for_string(rr, path).first
      sexp = Sexp.from_array sexp
      rb = Ruby2Ruby.new.process(sexp)
      File.open(target_path, 'w') do |f|
        f.write(rb)
      end
    end
  end
  
end