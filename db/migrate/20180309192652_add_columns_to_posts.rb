class AddColumnsToPosts < ActiveRecord::Migration[5.1]
  def change
    add_column :posts, :votes, :integer
    add_column :posts, :score, :decimal
  end
end
