class AddUnitsToZone < ActiveRecord::Migration
	def self.up
		add_column :zones, :artillery, :boolean
		add_column :zones, :jamming, :boolean
	end

	def self.down
		remove_column :zones, :artillery
		remove_column :zones, :jamming
	end
end
