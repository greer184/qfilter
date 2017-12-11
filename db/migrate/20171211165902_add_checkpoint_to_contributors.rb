class AddCheckpointToContributors < ActiveRecord::Migration[5.1]
  def change
    add_column :contributors, :checkpoint, :integer
  end
end
