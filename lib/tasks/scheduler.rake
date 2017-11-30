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
      content['result']['active_votes'].each do |x|
        voter = x['voter']
        if Contributor.where(username: voter).size == 0
          Contributor.create(username: voter, score: 1).save
        else
	  con = Contributor.find_by_username(voter)
          con.update_attribute(:score, con.score + 1)
        end  
      end
      if Contributor.where(username: post.author).size == 0
        Contributor.create(username: post.author, score: 5).save
      else
	con = Contributor.find_by_username(post.author)
        con.update_attribute(:score, con.score + 5)
      end
      post.destroy 
    end   
  end
 
end 