namespace :rewrite do
  
  desc "prepare for deployment by rewriting all .rr fils to .rb files"
  task :prepare => :environment do
    `find #{RAILS_ROOT} -name "*.rr"`.each do |rr_path|
      RewriteRails.rewrite_file(rr_path.strip)
    end
  end
  
end