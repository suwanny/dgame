require 'digest/sha1'
require 'gamerules'

class User < ActiveRecord::Base

  # Validation Stuff
  # ================

  attr_accessor               :password_confirmation

  validates_presence_of       :name
  validates_presence_of       :total_soldiers
  validates_presence_of       :turns
  validates_uniqueness_of     :name
  validates_numericality_of  :total_zones,    :only_integer => true
  validates_numericality_of  :total_soldiers,  :only_integer => true,  :greater_than_or_equal_to => 0
  validates_numericality_of  :turns,        :only_integer => true,  :greater_than_or_equal_to => 0
  validates_confirmation_of   :password
  validate                    :password_non_blank
  validate          :total_zones_equals_zone_count

  # Functions
  # =========

  public

  def self.authenticate( name, password )
    user = self.find_by_name(name)
    if user
      expected_password = encrypted_password( password, user.salt )
      if user.hashed_password != expected_password
        user = nil
      end
    end
    user
  end

  def password
    @password
  end

  def password=(pwd)
    @password = pwd
    return if pwd.blank?
    create_new_salt
    self.hashed_password = User.encrypted_password( self.password, self.salt )
  end

  # Added by Xin: change the viewport this user

  def change_viewport(x, y)
    self.viewport_x = x
    self.viewport_y = y
  end

  # Added by Xin: calculate the new turns after expanding

  def new_turns_after_expanding
    self.turns - GameRules::TURNS_CONSUMED_PER_EXPAND
  end

  # Added by Xin: calculate the new turns after attacking

  def new_turns_after_attacking
    self.turns - GameRules::TURNS_CONSUMED_PER_ATTACK
  end

  def new_total_soldiers_after_battle
    if self.total_soldiers <= GameRules::TOTAL_SOLDIERS_LOST_IN_BATTLE
      0
    else
      self.total_soldiers - GameRules::TOTAL_SOLDIERS_LOST_IN_BATTLE
    end
  end

  ## Takes a peek at how many turns the user has right now without saving this
  ## to the database.

  def peek_current_turn_count
    return turns + get_updated_turns()
  end

  ## Spends the given amount of turns on something another. This function will not only subtract
  ## turns, but add turns based on turn acquisition rate. Doesn't save.

  def spend_turns( tcount )
    mturns           = get_updated_turns()  # Amount of time we're adding.'
    turns           += mturns - tcount
    last_time_turns_commit  += mturns * GameRules::MINUTES_PER_TURN * 60  # Add time in seconds
  end

  ## If some sort of race condition occurs ( because Rails can't do true multi-database transactions )
  ## in which you spend turns, but can't get what you spent them on ( contestment over a zone, perhaps )
  ## then this function will refund those turns back to the user.

  def refund_turns( tcount )
    turns += tcount;
    save()
  end

  # training soldier: training new soldiers with spending turns..  
  def train_soldier(num_new_soldiers)
    required_turns = num_new_soldiers.to_i * GameRules::TURNS_PER_SOLDIER
    if self.turns < required_turns
      flash[:notice] = "Fail: You don't have enough turns for this amount of soldiers"
    else
      # update ..
      self.total_soldiers += num_new_soldiers.to_i
      self.turns -= required_turns
      self.save
    end
  end

  # Added by Xin: calculate the new turns that needs to be added after login

  def get_updated_turns
    @minutesPassed = (Time.now - last_time_turns_commit).round / 60
    @turnsGained = (@minutesPassed / GameRules::MINUTES_PER_TURN).round
    if (@turnsGained < 0)  #invalid value
      self.last_time_turns_commit = Time.now
      0
    else
      #for every login the gained turns do not exceed a certain number - punish long time no login
      #if @turnsGained > GameRules::MAX_TURNS_GAINED_PER_LOGIN
      # @turnsGained = GameRules::MAX_TURNS_GAINED_PER_LOGIN
      #end
      # Yes, the user shouldn't be allowed to stockpile turns, but the
      # most straightforward way to do this is to have a maximum amount of
      # turns that you _can_ stockpile. It's easy to understand.

      if self.turns + @turnsGained >  GameRules::MAX_TURN_STORAGE
        @turnsGained = GameRules::MAX_TURN_STORAGE - turns
      end

      @turnsGained
    end
  end

  # Xin: try to save the updated user information, if failed rewrite the flash[:notice] and return false,
  # else return true.

  def try_save
    if not self.save
      errors.each_full do |message|
        #flash[:notice] = message + params[:newturns]
      end
      false
    else
      true
    end
  end

  private

  def password_non_blank
    errors.add( :password, "Missing password" ) if hashed_password.blank?
  end

  def create_new_salt
    self.salt = self.object_id.to_s + rand.to_s
  end

  def total_zones_equals_zone_count
    errors.add( :total_zones, "Doesn't match of zones owned in Zones table!" ) if Zone.get_total_zones_for_user( id ) != total_zones
  end

  def self.encrypted_password( password, salt )
    string_to_hash = password + "wibble" + salt
    Digest::SHA1.hexdigest(string_to_hash)
  end

end
