class AddScoreToZone < ActiveRecord::Migration
	def self.up
		add_column :zones, :score, :integer
	end

	def self.down
		remove_column :zones, :score
	end
end
