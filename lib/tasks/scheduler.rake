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
    if limit > 1000
      post.destroy 
    end
  end
 
end 