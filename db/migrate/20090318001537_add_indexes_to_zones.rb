# the command creating this file "ruby script/generate migration add_indexes_to_zones""
# to apply it use "rake db:migrate""
class AddIndexesToZones < ActiveRecord::Migration
  def self.up
      add_index :zones, [:x, :y], :unique => true
      add_index :zones, :user_id
  end

  def self.down
      remove_index :zones, :user_id
      remove_index :zones, [:x, :y]
  end
end
