class ContributorsController < ApplicationController
  def index
  end

  def show
    @contributor = Contributor.find_by_username(params[:id].gsub("@", ""))
  end
end
