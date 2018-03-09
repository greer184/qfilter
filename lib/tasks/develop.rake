namespace :develop do
  task :update => :environment do
    api = Radiator::Api.new
    state = api.get_state('/created/q-filter')

    state['result']['content'].each do |x|
   
      # Get specific information
      permlink = x[1]['permlink']

      # Only grab post information if post is new
      if Post.where(permlink: permlink).size == 0
        author = x[1]['author']
        cat = x[1]['url'].split("/")[1]
        url = "https://steemit.com" + x[1]['url']
        votes = x[1]['active_votes'].size
	title = x[1]['root_title']
        parse = JSON.parse(x[1]['json_metadata'])['image']
        if !parse.nil?
      	  image = parse[0]
        else
          image = "empty"
        end
 
        # Enter author into the database if not there
        Contributor.add_contributor(author)

        # Only store new posts where author contributes to ecosystem
        if Contributor.find_by_username(author).weight >= 0.0  
          post = Post.create(author: author, permlink: permlink, category: cat,
			     votes: votes, score: 0.0, url: url, image: image)
          post.save
	  post.update_score(api)
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

  task :calculate => :environment do
    api = Radiator::Api.new
    Post.all.each do |post|
      post.update_score(api)
    end
  end

end