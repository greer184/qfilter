namespace :utility do

  task :checkpoint => :environment do

    # Apply Checkpoint and Reset Point Counter
    Contributor.all.each do |con|
      con.update_attribute(:checkpoint, con.score)
    end
  end

end