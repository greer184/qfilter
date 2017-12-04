task :update => :environment do
  api = Radiator::Api.new
  state = api.get_state('/created/q-filter')

  state['result']['content'].each do |x|
    permlink = x[1]['permlink']
    author = x[1]['author']
    if Post.where(permlink: permlink).size == 0
      post = Post.create(author: author, permlink: permlink)
      post.save
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

      # Reward only "quality" posts
      if (score > 5.0)
        score = (score - 5.0)**2
      else
        score = 0.0
      end
      
      # Add to the contribution score of author
      Contributor.add_contribution(post.author, score.to_i)

      # Remove post reference from database
      post.destroy 

    end   
  end
 
end 