class AddColorToUser < ActiveRecord::Migration
	def self.up
		add_column :users, :color_r, :integer
		add_column :users, :color_g, :integer
		add_column :users, :color_b, :integer
	end

	def self.down
		remove_column :users, :color_r
		remove_column :users, :color_g
		remove_column :users, :color_b
	end
end
