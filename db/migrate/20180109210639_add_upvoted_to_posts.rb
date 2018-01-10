class AddUpvotedToPosts < ActiveRecord::Migration[5.1]
  def change
    add_column :posts, :upvoted, :boolean, :default => false
  end
end
