namespace :rewrite do
  
  desc "rewrite all .rr files to .rb files"
  task :all => :environment do
    `find #{RAILS_ROOT} -name "*.rr"`.each do |rr_path|
      RewriteRails.rewrite_file(rr_path.strip)
    end
  end
  
  desc "clear all cached .rb files"
  task :clear => :environment do
    rewritten_folder = File.expand_path(RewriteRails.cache_folder_name())
    if rewritten_folder != File.expand_path(RAILS_ROOT)
      `find #{rewritten_folder} -name "*.rb"`.each do |rb_path|
        File.delete(rb_path.strip)
      end
    else
      raise "You cannot clear cached files if you are rewriting to the rails root: you will delete all .rb files as well"
    end
  end
  
  desc "prepare for deployment by rewriting all .rr files to .rb files"
  task :prepare => [:clear, :all]
  
end