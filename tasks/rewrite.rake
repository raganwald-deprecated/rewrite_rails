namespace :rewrite do
  
  desc "ensure there is a target directory for rewriting"
  task :init => :environment do
    rewritten_folder = File.expand_path(RewriteRails.cache_folder_name())
    File.makedirs(rewritten_folder)
  end
  
  desc "rewrite all .rr files to .rb files"
  task :all => :environment do
    `find #{RAILS_ROOT} -name "*.rr"`.each do |rr_path|
      RewriteRails.rewrite_file(rr_path.strip)
    end
  end
  
  desc "clear all cached .rb files and sub-folders"
  task :clear => :environment do
    rewritten_folder = File.expand_path(RewriteRails.cache_folder_name())
    if rewritten_folder != File.expand_path(RAILS_ROOT)
      # delete .rb files
      `find #{rewritten_folder} -name "*.rb"`.each do |rb_path|
        File.delete(rb_path.strip)
      end
      # then subfolders
      `find #{rewritten_folder} -name "*"`.map(&:strip).reverse.select do |path|
        File.directory?(path) && Dir.entries(path).size == 2
      end.reject do |path|
        File.expand_path(path) == rewritten_folder
      end.each { |path| Dir.rmdir(path) }
    else
      raise "You cannot clear cached files if you are rewriting to the rails root: you will delete all .rb files as well"
    end
  end
  
  desc "prepare for deployment by rewriting all .rr files to .rb files"
  task :prepare => [:init, :clear, :all]
  
end