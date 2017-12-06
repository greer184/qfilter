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

  posts = Post.all
  posts.order! 'created_at'
  limit = 0
  posts.each do |post|
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