class CreateZones < ActiveRecord::Migration
  def self.up
    create_table :zones do |t|
      t.integer :x
      t.integer :y
      t.integer :user_id
      t.integer :soldiers

      t.timestamps
    end
  end

  def self.down
    drop_table :zones
  end
end
