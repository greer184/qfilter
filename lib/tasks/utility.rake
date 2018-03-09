namespace :utility do

  task :reduce_precision => :environment do
    Contributor.all.each do |con|
      con.update_attribute(:weight, con.weight.round(10))
    end
  end

  task :upgrade_posts => :environment do
    api = Radiator::Api.new
    Post.all.each do |post|
      content = api.get_content(post.author, post.permlink)
      url = "https://steemit.com" + content['result']['url']
      title = content['result']['root_title']
      votes = 0
      parse = JSON.parse(content['result']['json_metadata'])['image']
      if !parse.nil?
         image = parse[0]
      else 
         image = "empty"
      end
      post.update_columns(url: url, title: title, votes: votes, image: image)
    end
  end

end