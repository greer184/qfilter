namespace :develop do
  task :update => :environment do
    api = Radiator::Api.new
    state = api.get_state('/created/q-filter')

    state['result']['content'].each do |x|
   
      # Get specific information
      permlink = x[1]['permlink']
      author = x[1]['author']

      # Enter author into the database if not there
      Contributor.add_contribution(author, 0)

      # Only store new posts where author contributes to ecosystem
      if Contributor.find_by_username(author).score >= 0 
        if Post.where(permlink: permlink).size == 0 
          post = Post.create(author: author, permlink: permlink)
          post.save
        end
      end  
  
    end	

    Post.all.each do |post|
      if (1.week.ago - post.created_at) > 0
        content = api.get_content(post.author, post.permlink)
        votes = content['result']['active_votes']

        # Added to contribution score of voters
        votes.each do |x|
          Contributor.add_contribution(x['voter'], 1)
        end
        print "reached"
      
        # Find winners of curation and author rewards
        curation_winner = post.compute_score('curation', votes)
        score = post.compute_score('stake', votes)

        # Reward curation winner with bonus contribution points
        Contributor.add_contribution(curation_winner, 10)

        # Reward curation winner with SBD
        total_cash = api.find_account('qfilter').sbd_balance.to_f
        money = (total_cash / Post.all.count).round(3) - 0.001 
        print money

        # Reward only "quality" posts, punish "bad" posts
        if (score >= 5.0)
          score = (score - 5.0)**2
          Contributor.add_contribution(post.author, score.to_i)
        else
          score = -1.0 * (score - 5.0)**2
          Contributor.add_contribution(post.author, score.to_i)
        end

        # Remove post reference from database
        post.destroy 

      end   
    end
 
  end 

  task :upvote_test => :environment do

    # Only vote on posts after 48 hours
    Post.all.each do |post|
      if (2.days.ago - post.created_at) > 0 and !post.upvoted
 
        # Post should be marked as updated
        post.update_attribute(:upvoted, true) 
        print "works"
      end
    end
  end
end