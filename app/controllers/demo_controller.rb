class DemoController < ApplicationController

  def stake
    @feed = aggregate_posts('stake')
    render 'index'
  end
  
  def reputation
    @feed = aggregate_posts('reputation')
    render 'index'
  end

  def contribution
    @feed = aggregate_posts('contribution')
    render 'index'
  end
    
  private
  def aggregate_posts(algorithm)
    feed = []
    api = Radiator::Api.new
    Post.all.each do |post|
      feed.append(post.build_post(algorithm, api))
    end
    feed
  end
end
