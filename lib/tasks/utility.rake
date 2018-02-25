namespace :utility do

  task :reduce_precision => :environment do
    Contributor.all.each do |con|
      con.update_attribute(:weight, con.weight.round(10))
    end
  end

end