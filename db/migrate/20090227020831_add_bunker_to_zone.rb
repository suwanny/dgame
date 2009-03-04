class AddBunkerToZone < ActiveRecord::Migration
	def self.up
		add_column :zones, :bunker, :boolean
	end

	def self.down
		remove_column :zones, :bunker
	end
end
