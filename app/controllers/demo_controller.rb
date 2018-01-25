class DemoController < ApplicationController

  def stake
    @feed = aggregate_posts('stake')
    render 'index'
  end
  
  def reputation
    @feed = aggregate_posts('reputation')
    render 'index'
  end

  def participation
    @feed = aggregate_posts('contribution')
    render 'index'
  end

  # In Development
  def showcase
    api = Radiator::Api.new
    leaders = Contributor.find_best(20)
    names = leaders.map{ |x| x = x.username } 
    # Work in Progress
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
