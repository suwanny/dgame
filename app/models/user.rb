require 'digest/sha1'

class User < ActiveRecord::Base

	has_many					:zones

    # Validation Stuff
    # ================

    attr_accessor               :password_confirmation

    validates_presence_of       :name
    validates_presence_of       :total_soldiers
	validates_presence_of       :total_zones
    validates_presence_of       :turns
	validates_presence_of		:color_r
	validates_presence_of		:color_g
	validates_presence_of		:color_b
	validates_presence_of		:jammingcount
	validates_presence_of		:email
	validates_presence_of		:score
    validates_uniqueness_of     :name
	validates_numericality_of  	:score,    			:only_integer => true,  :greater_than_or_equal_to => 0
    validates_numericality_of  	:total_zones,    	:only_integer => true,  :greater_than_or_equal_to => 0
    validates_numericality_of  	:total_soldiers,  	:only_integer => true,  :greater_than_or_equal_to => 0
    validates_numericality_of  	:turns,        		:only_integer => true,  :greater_than_or_equal_to => 0
	validates_numericality_of  	:jammingcount, 		:only_integer => true,  :greater_than_or_equal_to => 0
	validates_numericality_of  	:color_r,      		:only_integer => true,  :greater_than_or_equal_to => 0,	:less_than_or_equal_to => 255
	validates_numericality_of  	:color_g,      		:only_integer => true,  :greater_than_or_equal_to => 0,	:less_than_or_equal_to => 255
	validates_numericality_of  	:color_b,      		:only_integer => true,  :greater_than_or_equal_to => 0,	:less_than_or_equal_to => 255
    validates_confirmation_of   :password
    validate                    :password_non_blank
    #validate          			:total_zones_equals_zone_count
	#validate					:total_soldiers_equal_zone_soldier_total
	#validate					:score_is_sum_of_owned_zones

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

	def self.get_top_five_users 
		return self.find( :all, :order => "score DESC", :limit => 5, :select => "name, score" )
	end

	def self.get_user_count
		return self.count
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

    ## add turns based on turn acquisition rate. Doesn't save

    def update_turns_by_time
        mturns = get_updated_turns()  # Amount of time we're adding.'
        self.turns += mturns
        if not self.last_time_turns_commit
            self.last_time_turns_commit = Time.now
        else
            self.last_time_turns_commit += mturns * GameRules::MINUTES_PER_TURN * 60  # Add time in seconds
        end
    end

    ## update last login time

    def update_last_login
        last_time_login = Time.now
    end

    ## Spends the given amount of turns on something another. This function will not only subtract
    ## turns, but add turns based on turn acquisition rate. Doesn't save.

    def spend_turns( tcount )
        update_turns_by_time()
        self.turns -= tcount
    end

    ## If some sort of race condition occurs ( because Rails can't do true multi-database transactions )
    ## in which you spend turns, but can't get what you spent them on ( contestment over a zone, perhaps )
    ## then this function will refund those turns back to the user.

    def refund_turns( tcount )
        self.turns += tcount;
    end

    # Train soldiers by spending the given amount of turns. Returns:
    # - Amount of soldiers trained!		<- Success! Returns amount of new soldiers.
    # - :database_error_or_bad			<- Error, couldn't save.
    # - :invalid_parameter				<- Error, bad params.
    # - :not_enough_turns				<- Error, not enough turns.
    # def train_soldiers_with_turns( turncount )
    #    return :invalid_parameter if !turncount.is_a?(Numeric)                                        # Check the parameters.
    #    return :not_enough_turns if turncount > peek_current_turn_count()
    #    nscount             = GameRules::get_soldier_train_count( self.total_soldiers, turncount )    # Grab the amount of soldiers that will be trained.
    #    self.total_soldiers += nscount                                                                # Increase this amount of soldiers.
    #    self.turns            -= turncount                                                            # Remove this amount of turns.
    #    return :database_error if !self.save                                                        # Save! Or return an error.
    #    return nscount                                                                                # Success!
    #end

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
        if (not last_time_turns_commit)
            return 0
        end
        if turns >= GameRules::MAX_TURN_STORAGE
            return 0
        end
        
        minutesPassed = (Time.now - last_time_turns_commit).round / 60
        turnsGained = (minutesPassed / GameRules::MINUTES_PER_TURN).round
        if (turnsGained < 0)  #invalid value
            last_time_turns_commit = Time.now
            return 0
        else
            #for every login the gained turns do not exceed a certain number - punish long time no login
            #if @turnsGained > GameRules::MAX_TURNS_GAINED_PER_LOGIN
            # @turnsGained = GameRules::MAX_TURNS_GAINED_PER_LOGIN
            #end
            # Yes, the user shouldn't be allowed to stockpile turns, but the
            # most straightforward way to do this is to have a maximum amount of
            # turns that you _can_ stockpile. It's easy to understand.

            if turns + turnsGained >  GameRules::MAX_TURN_STORAGE
                turnsGained = GameRules::MAX_TURN_STORAGE - turns
            end

            return turnsGained
        end
    end

    # Xin: try to save the updated user information, if failed rewrite the flash[:notice] and return false,
    # else return true.

    def get_error_msg
        errorMsg = ""
        errors.each_full do |message|
            errorMsg << message
        end
        return errorMsg
    end

    ## get the average soldiers per zone
    def avg_soldiers_per_zone  
       if total_zones == 0
           return total_soldiers
       else
           return total_soldiers.to_f / total_zones.to_f
       end
    end

=begin
    def self.login(name, password)
        user = authenticate( name, password )
        if user
            oldTurns = user.turns
            user.update_turns_by_time()
            user.update_last_login()
            successMsg = "#{user.turns - oldTurns} turns gained after login."
            if not user.save
                return false#user.get_error_msg + "Can not update user data!"
            else
                #flash[:notice] = successMsg
            end

            session[:user_id] = user.id
            session[:user_name] = user.name
            session[:turns] = user.turns
            session[:soldiers] = user.total_soldiers
            session[:alliance] = user.alliance   # for StatesGame
            session[:zones] = user.total_zones        # for StatesGame

            return true #successMsg
            #redirect_to( :action => "info" )
        else
            return false
            #flash[:notice] = "Invalid User/Password."
            #redirect_to( :action => "index" )
        end
    end
=end

    # do not want the save to always fail, should check the values
    def save_wrapup
        self.score = 0 if self.score == nil
        self.total_zones = 0 if self.total_zones == nil
        self.total_soldiers = 0 if self.total_soldiers == nil
        self.turns = 0 if self.turns == nil
        self.jammingcount = 0 if self.jammingcount == nil
        self.color_r = 0 if self.color_r == nil
        self.color_g = 0 if self.color_g == nil
        self.color_b = 0 if self.color_b == nil
        self.email = "unknown" if self.email == nil
        return self.save
    end

    private

    def password_non_blank
        errors.add( :password, "Missing password" ) if hashed_password.blank?
    end

    def create_new_salt
        self.salt = self.object_id.to_s + rand.to_s
    end

    def total_zones_equals_zone_count
        actual_zones_count = Zone.get_total_zones_for_user( id )
        if actual_zones_count != total_zones
            self.total_zones = actual_zones_count
            errors.add( :total_zones, "not matching the Zones database")
        end
	end

	def total_soldiers_equal_zone_soldier_total
        totalSoldiers = Zone.sum('soldiers',  :conditions => { :user_id => self.id })

		if totalSoldiers != self.total_soldiers
            self.total_soldiers = totalSoldiers
        	errors.add( :total_soldiers, "Soldier count for user doesn't match soldiers in zones!")
		end
	end

	def score_is_sum_of_owned_zones
        totalScores = Zone.sum('score',  :conditions => { :user_id => self.id })

		if totalScores != self.score
            self.score = totalScores
			errors.add( :score, "Score is not a summation of all the zones' scores" )
		end
	end

    def self.encrypted_password( password, salt )
        string_to_hash = password + "wibble" + salt
        Digest::SHA1.hexdigest(string_to_hash)
	end
end
