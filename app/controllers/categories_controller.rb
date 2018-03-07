class CategoriesController < ApplicationController
  def show
    @feed = Post.aggregate_posts('contribution', params[:id])
  end

end
