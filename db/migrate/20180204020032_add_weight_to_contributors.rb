class AddWeightToContributors < ActiveRecord::Migration[5.1]
  def change
    add_column :contributors, :weight, :decimal, :default => 1000.0
  end
end
