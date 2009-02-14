class CreateStates < ActiveRecord::Migration
  def self.up
    create_table :states do |t|
      t.string :state_name
      t.integer :user_id
      t.integer :soldiers
      t.integer :alliance

      t.timestamps
    end
  end

  def self.down
    drop_table :states
  end
end
