class CategoriesController < ApplicationController
  def show
    @feed = aggregate_posts(params[:id])
  end

  private
  def aggregate_posts(category)
    feed = []
    api = Radiator::Api.new
    Post.all.each do |post|
      if (post.category == category)
        feed.append(post.build_post('contribution', api))
      end
    end
    feed
  end

end
