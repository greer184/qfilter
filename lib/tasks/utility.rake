namespace :utility do
  task :checkpoint => :environment do
    Contributor.all.each do |con|
      con.update_attributes(checkpoint: con.score)
    end
  end
end