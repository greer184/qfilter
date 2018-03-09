class DemoController < ApplicationController

  def stake
    @feed = Post.aggregate_posts('stake')
    render 'index'
  end
  
  def reputation
    @feed = Post.aggregate_posts('reputation')
    render 'index'
  end

  def participation
    @feed = Post.aggregate_posts('contribution')
    render 'index'
  end
  
end
