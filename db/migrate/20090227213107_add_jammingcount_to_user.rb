class AddJammingcountToUser < ActiveRecord::Migration
	def self.up
	  	add_column :users, :jammingcount, :integer
	end

	def self.down
		remove_column :users, :jammingcount
	end
end
