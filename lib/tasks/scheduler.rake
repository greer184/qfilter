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
      
      # Find winners of curation and author rewards
      curation_winner = post.compute_score('curation', votes)
      score = post.compute_score('stake', votes)

      # Reward curation winner with bonus contribution points
      Contributor.add_contribution(curation_winner, 10)

      # Reward curation winner with SBD
      total_cash = api.find_account('qfilter').sbd_balance.to_f
      money = (total_cash / Post.all.count).round(3) - 0.001 
  
      # Build Transaction
      active_key = Permission.find_by_name('qfilter-active-key').key
      transaction = Radiator::Transaction.new(wif: active_key)
      transfer = {
        type: :transfer,
        from: 'qfilter',
        to: curation_winner,
        amount: money.to_s + ' SBD',
        memo: 'qFilter Vote Lottery Prize'
      }
 
      # Process Transaction
      transaction.operations << transfer
      transaction.process(true)

      # Reward only "quality" posts, punish "bad" posts
      if (score >= 5.0)
        score = (score - 5.0)**2
        Contributor.add_contribution(post.author, score.to_i)
      else
        Contributor.add_contribution(post.author, -25)
      end

      # Remove post reference from database
      post.destroy 

    end   
  end
 
end 

task :upvote => :environment do
  api = Radiator::Api.new
  
  Post.all.each do |post|

    # Only vote on posts after 48 hours
    if (2.days.ago - post.created_at) > 0 and !post.upvoted
 
      # Perform Calculations
      content = api.get_content(post.author, post.permlink)
      votes = content['result']['active_votes']
      weight = post.compute_score('stake', votes)

      # Approve Transaction
      active_key = Permission.find_by_name('qfilter-active-key').key
      transaction = Radiator::Transaction.new(wif: active_key)

      vote = {
        type: :vote,
        voter: 'qfilter',
        author: post.author,
        permlink: post.permlink,
        weight: ((weight * 2000.0) - 10000.0).to_i
      }

      transaction.operations << vote
      transaction.process(true)

      post.update_attribute(:upvoted, true) 
    end
  end
end