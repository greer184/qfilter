class AddColumnsToPosts < ActiveRecord::Migration[5.1]
  def change
    add_column :posts, :votes, :integer
    add_column :posts, :score, :decimal
    add_column :posts, :url, :string
    add_column :posts, :image, :string
    add_column :posts, :title, :string
  end
end
