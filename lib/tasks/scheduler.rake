task :update => :environment do
  api = Radiator::Api.new
  state = api.get_state('/created/q-filter')

  state['result']['content'].each do |x|
   
    # Get specific information
    permlink = x[1]['permlink']
    author = x[1]['author']
    cat = x[1]['url'].split("/")[1]

    # Enter author into the database if not there
    Contributor.add_contributor(author)

    # Only store new posts where author contributes to ecosystem
    if Contributor.find_by_username(author).weight >= 0 
      if Post.where(permlink: permlink).size == 0 
        post = Post.create(author: author, permlink: permlink, category: cat)
        post.save
      end
    end  
  
  end	

  Post.all.each do |post|
    if (1.week.ago - post.created_at) > 0
      content = api.get_content(post.author, post.permlink)
      votes = content['result']['active_votes']
      
      # Find winners of curation and author rewards
      curation_winner = post.compute_score('curation', votes)
      score = post.compute_score('contribution', votes)

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

      # Find total allocation for this post
      allocation = Contributor.all.count * 1000.0 / Post.all.count

      # Add to contribution score of voters
      share = allocation * 0.5 / votes.size
      votes.each do |x|
         Contributor.add_contributor(x['voter'])
         con = Contributor.find_by_username(x['voter'])
         con.update_attribute(:weight, con.weight + share)
      end

      # Reward curation winner with bonus contribution points
      curator = Contributor.find_by_username(curation_winner)
      curator.update_attribute(:weight, curator.weight + allocation * 0.1)

      # Reward only "quality" posts, punish "bad" posts
      quality_share = ((score - 5.0) / 5.0) * 0.4 * allocation
      author = Contributor.find_by_username(post.author)
      author.update_attribute(:weight, author.weight + quality_share)

      # Normalize
      Contributor.normalize()

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
      weight = post.compute_score('vote', votes)

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