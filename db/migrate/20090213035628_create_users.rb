class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name
      t.string :hashed_password
      t.string :salt
      t.string :email
      t.integer :turns
      t.integer :alliance
      t.integer :total_soldiers, :default => 0
      t.integer :total_zones, :default => 0
      t.integer :score
      t.datetime :last_time_turns_commit
      t.datetime :last_time_login
      t.text :public_info
      t.float :viewport_x
      t.float :viewport_y
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
