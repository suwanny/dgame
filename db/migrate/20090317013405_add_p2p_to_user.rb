class AddP2pToUser < ActiveRecord::Migration
	def self.up
		add_column :users, :p2pid, :string
		add_column :users, :p2pid_timestamp, :datetime

	end

	def self.down
		remove_column :users, :p2pid
	end
end
