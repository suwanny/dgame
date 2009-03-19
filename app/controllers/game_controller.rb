class GameController < ApplicationController
    USE_MEMCACHED      = true # indicate whether to use the memcached or not

  # Methods for Pages
  # =================
 
	def index
		@user = User.find_by_id(session[:user_id]) 
	end

	def profile

	end

	def ranking

	end

	def inbox
		
	end

  # Methods for Flash Applet to grab info with.
  # ===========================================

  ## Returns the positions of all the zones the given user can expand into.
  ## Return values:
  ## @result    Array of hash objects with :x and :y parameters for integer zone coordinates.
  ## @error    :user_not_found
  ##        :database_error
  def get_expandable_zones
    begin
      user   = User.find_by_id( session[:user_id] )
      if user.nil?
        @error = :user_not_found
      else
        @result = Zone.get_expandable_zones( session[:user_id] )
      end
    rescue
      @error = :database_error
    end

    respond_to do |format|
      format.xml { render :layout => false }
    end
  end

  ## User attacks the given zone owned by another player.
  ## Params:
  ## :targetX, :targetY, implicit session data.
  ## Return values:
  ## @result:    Hash with :result, :time and array of potentially altered zones in :czones
  ##         :invalid_defending_zone    <- No zone at that position.
  ##         :user_lookup_error      <- Could not find attacking or defending user.
  ##         :no_attackers        <- No adjacent zones by which to attack with!
  ##         :database_error        <- Some sort of database error.
  ##        :invalid_params        <- Parameters are not good.
  ##        :same_user          <- Attempting to attack self.
  ##        :not_enough_soldiers    <- Attacker doesn't have enough soldiers.
  def attack_zone
    targetX = Float(params[:targetX]).to_i rescue false
    targetY = Float(params[:targetY]).to_i rescue false

    if !targetX.is_a?(Numeric) || !targetY.is_a?(Numeric)
      @result = :invalid_params
    else
      begin
        @result = UserZone.attack_zone( session[:user_id], targetX, targetY )
        @userid = session[:user_id]
      rescue
        @result = :database_error
      end
    end

    respond_to do |format|
      format.html do
        flash[:notice] = @result if @result != true
                redirect_to(:controller => 'zones', :action => 'index')
            end
      format.xml { render :layout => false}
    end
  end

  ## User expands into the given zone. This function will also work if the user doesn't have any zones yet!
  ## Otherwise it checks if ( params[:targetX], params[:targetY] ) is adjacent to any currently owned zones.
  ## Parameters are:
  ## - :targetX, :targetY
  ##
  ## Return values:
  ## @result:   true         <- Successful expansion!
  ##         :user_auth_error      <- User authentication error.                                7
  ##         :zone_already_owned      <- The zone is already owned by a player. 8
  ##         :not_enough_turns      <- The user doesn't have enough turns to do this. 9
  ##         :zone_not_touching      <- The target zone is not touching the player's territory ( if it's not their first. ) 10
  ##         :database_error        <- Database error!
  ## :not_enough_soldiers    <- Not enough adjacent soldiers to take the zone.
  def expand_into_zone
    targetX = Float(params[:targetX]).to_i rescue false
    targetY = Float(params[:targetY]).to_i rescue false

    if !targetX.is_a?(Numeric) || !targetY.is_a?(Numeric)
      @result = :invalid_params
    else
      begin
        @result = UserZone.expand_into_zone( session[:user_id], targetX, targetY )
      rescue
        @result = :database_error
      end
    end

    respond_to do |format|
      format.html do
                if (@result == true)
                    redirect_to( :controller => 'zones', :action => 'index' )
                else
                    flash[:notice] = @result
                    redirect_to( :controller => 'zones', :action => 'index' )
                end
            end
      format.xml { render :layout => false}
    end
  end

  ## Returns all zone data in a given bounding box. Information will be passed into @zones and
  ## it will be an array of Zone objects. Wont return unit information if the user has a jamming tower...
  ## Params:
  ## :max_x, :min_x, :max_y, :min_y, no session data needed. X and Y is integer X/Y, not lat/long
  ##
  ## Return values:
  ## @result:    :invalid_params
  ##        :database_error
  ##         Array of Zone objects!
  def get_zone_data
    minX = Float(params[:min_x]).to_i rescue false
    maxX = Float(params[:max_x]).to_i rescue false
    minY = Float(params[:min_y]).to_i rescue false
    maxY = Float(params[:max_y]).to_i rescue false

    if !minX.is_a?(Numeric) || !maxX.is_a?(Numeric) || !minY.is_a?(Numeric) || !maxY.is_a?(Numeric)
      @result = :invalid_params
    else
      begin
        @userid = session[:user_id]
        @result = UserZone.get_zone_data( minX, maxX, minY, maxY )
      rescue
        @result = :database_error
      end
    end

    respond_to do |format|
      format.xml { render :layout => false}
    end
  end

  ## Returns all the zones that can be attacked by the user. Does not take into account cost to attack.
  ## This function will return an array of Zone objects ( for the view to format as it likes )
  ##
  ## Return values
  ## @result    Array of Zone objects!
  ##        :database_error
  ##        :user_not_found
  def get_attackable_zones
    begin
      @result = Zone.get_attackable_zones( session[:user_id] )
    rescue
     @result = :database_error
    end
    respond_to do |format|
      format.xml { render :layout => false}
    end
  end

  ## Returns # of soldiers the player would get by spending 1 turn.
  ## Paramters:  implicit session data.
  ## Return values
  ## @result    Amount of soldiers you'd get!
  ##        :invalid_param          <- No such user! Or DB error.
  def peek_train_soldiers
    @result = UserZone.peek_soldier_train_results( session[:user_id], 1 )
    respond_to do |format|
      format.xml { render :layout => false}
    end
  end

  ## Trains 1 turn worth of soldiers at a given location.
  ## Parameters:
  ##    :targetX, targetY
  ## Returns values:
  ## @result    Hash with :trained, :newcountatzone, :newtotal, :nextup
  ##       :database_error        <- Error, couldn't save.
  ##       :invalid_parameter      <- Error, bad params.
  ##       :not_enough_turns      <- Error, not enough turns.
  ##        :user_auth_error      <- Error, couldn't find user.
  ##        :no_such_zone         <- If the zone doesn't belong to anyone
  ##        :user_zone_mismatch      <- Zone isn't owned by the given player.
  def train_soldiers
    targetX = Float(params[:targetX]).to_i rescue false
    targetY = Float(params[:targetY]).to_i rescue false

    if !targetX.is_a?(Numeric) || !targetY.is_a?(Numeric)
      @result = :invalid_parameter
    else
      begin
        @result = UserZone.train_soldiers( session[:user_id], targetX, targetY )
      rescue
        @result = :database_error
      end
    end

    respond_to do |format|
      format.html do
                if (@result == true)
                    redirect_to(:controller => 'zones', :action => 'index')
                else
                    flash[:notice] = @result
                    redirect_to(:controller => 'zones', :action => 'index')
                end
            end
      format.xml { render :layout => false}
    end
  end

  ## Returns zone data for a given zone.
  ## Params:
  ## :targetX, :targetY
  ##
  ## Return values:
  ## @result:    :invalid_params
  ##        :database_error
  ##         Zone object in @result, user_id or nil in @userid!
  def get_single_zone_info
      targetX = Float(params[:targetX]).to_i rescue false
    targetY = Float(params[:targetY]).to_i rescue false

    if !targetX.is_a?(Numeric) || !targetY.is_a?(Numeric)
      @result = :invalid_params
    else
      begin
        @userid = session[:user_id]
        @result = Zone.get_zone_at( targetX, targetY )
      rescue
        @result = :database_error
      end
    end

    respond_to do |format|
      format.xml { render :layout => false }
    end
  end

  ## Will transfer soldiers between the two zones. Zones need to share and edge, be owned by
  ## the given player, and have enough soldiers.
  ## Parameters:
  ##     :sourceX, :sourceY -> :targetX, :targetY, :count
  ## Return value:
  ## @result    hash with :czones and :time
  ##        :user_auth_error
  ##        :database_error
  ##        :not_enough_soldiers
  ##        :must_remain_one
  ##        :zones_not_owned
  ##        :zones_not_adjacent
  ##        :invalid_parameters
  ##        :not_enough_turns
  def move_soldiers
    targetX = Float(params[:targetX]).to_i rescue false
    targetY = Float(params[:targetY]).to_i rescue false
    sourceX = Float(params[:sourceX]).to_i rescue false
    sourceY = Float(params[:sourceY]).to_i rescue false
    sCount  = Float(params[:count] ).to_i rescue false

    if !targetX.is_a?(Numeric) || !targetY.is_a?(Numeric)
     !sourceX.is_a?(Numeric) || !sourceY.is_a?(Numeric) || !sCount.is_a?(Numeric)
      @result = :invalid_parameters
    else
      begin
        @result = UserZone.move_soldiers( session[:user_id], targetX, targetY, sourceX, sourceY, sCount )
      rescue
        @result = :database_error
      end
    end

    respond_to do |format|
      format.xml { render :layout => false }
    end
  end

  ## Returns constants for artillery/bunker/tower costs.
  def get_costs
    @result = { :bunker => GameRules::COST_BUNKER, :artillery => GameRules::COST_ARTILLERY, :jamming => GameRules::COST_JAMMING_TOWER }

    respond_to do |format|
      format.xml { render :layout => false }
    end
  end

  ## Similar to soldiers. Moves em!
  ## Parameters:
  ##     :sourceX, :sourceY -> :targetX, :targetY
  ## Return values:
  ## @result    hash with :czones and :time
  ##        :user_auth_error
  ##        :database_error
  ##        :no_artillery_at_source
  ##        :artillery_at_target
  ##        :zones_not_owned
  ##        :zones_not_adjacent
  ##        :invalid_parameters
  ##        :not_enough_turns
  def move_artillery
    targetX = Float(params[:targetX]).to_i rescue false
    targetY = Float(params[:targetY]).to_i rescue false
    sourceX = Float(params[:sourceX]).to_i rescue false
    sourceY = Float(params[:sourceY]).to_i rescue false

    if !targetX.is_a?(Numeric) || !targetY.is_a?(Numeric)
     !sourceX.is_a?(Numeric) || !sourceY.is_a?(Numeric)
      @result = :invalid_parameters
    else
      begin
        @result = UserZone.move_artillery( session[:user_id], targetX, targetY, sourceX, sourceY )
      rescue
        @result = :database_error
      end
    end

    respond_to do |format|
      format.xml { render :layout => false }
    end
  end

  ## Build an artillery at the given zone.
  ## Parameters
  ##     :targetX, :targetY
  ## Return values:
  ## @result    hash with :czones and :time
  ##        :user_auth_error
  ##        :database_error
  ##        :invalid_parameters
  ##        :zone_not_owned
  ##        :already_artillery
  ##        :insufficient_turns
  def build_artillery
    targetX = Float(params[:targetX]).to_i rescue false
    targetY = Float(params[:targetY]).to_i rescue false

    if !targetX.is_a?(Numeric) || !targetY.is_a?(Numeric)
      @result = :invalid_parameters
    else
      begin
        @result = UserZone.build_artillery( session[:user_id], targetX, targetY )
      rescue
        @result = :database_error
      end
    end

    respond_to do |format|
      format.xml { render :layout => false }
    end
  end

  ## Build a bunker at the given zone.
  ## Parameters
  ##     :targetX, :targetY
  ## Return values:
  ## @result    hash with :czones and :time
  ##        :user_auth_error
  ##        :database_error
  ##        :invalid_parameters
  ##        :zone_not_owned
  ##        :already_bunker
  ##        :insufficient_turns
  def build_bunker
    targetX = Float(params[:targetX]).to_i rescue false
    targetY = Float(params[:targetY]).to_i rescue false

    if !targetX.is_a?(Numeric) || !targetY.is_a?(Numeric)
      @result = :invalid_parameters
    else
      begin
        @result = UserZone.build_bunker( session[:user_id], targetX, targetY )
      rescue
        @result = :database_error
      end
    end

    respond_to do |format|
      format.xml { render :layout => false }
    end
  end

  ## Returns information about a given user.
  ## Parameters:
  ##     :userid or nil if want to get own data ( needs session info in that case. )
  ## Returns:
  ##    User object
  ##    :invalid_param
  ##    :no_user
  def get_user_info
    if params[:userid] == nil
      @userid = session[:user_id]
    else
      @userid = Float(params[:userid]).to_i rescue false
    end

    if !@userid.is_a?(Numeric)
      @result = :invalid_param
    else
      @result = User.find_by_id( @userid )
      if @result == nil
        @result = :no_user
      end
      @userid = session[:user_id]
    end

    respond_to do |format|
      format.xml { render :layout => false }
    end
  end

  ## Sets the viewport location on the user object for reference.
  ## Parameters:
  ##     :x, :y
  ## Return values:
  ## @result    true
  ##        :user_auth_error
  ##        :invalid_parameters
  ##        :database_error
  def set_viewport_data
    targetX = Float(params[:targetX]) rescue false
    targetY = Float(params[:targetY]) rescue false

    if !targetX.is_a?(Numeric) || !targetY.is_a?(Numeric)
      @result = :invalid_parameters
    else
      begin
        user = User.find_by_id( session[:user_id] )
        if user == nil
          @result = :user_auth_error
        else
          user.change_viewport( targetX, targetY )
          user.save()
          @result = { :result => true, :user => user }
        end
      rescue
        @result = :database_error
      end
    end

    respond_to do |format|
      format.xml { render :layout => false }
    end
  end

  ## Returns the amount of turns it will take to attack a given zone.
  ## Parameters:
  ##    :targetX, :targetY
  ## Return values
  ## @result    amount of turns as an integer
  ##        :user_auth_error
  ##        :database_error
  ##        :invalid_params
  ##        :invalid_target
  ##        :cant_attack_zone
  def get_attack_cost
    targetX = Float(params[:targetX]).to_i rescue false
    targetY = Float(params[:targetY]).to_i rescue false

    if !targetX.is_a?(Numeric) || !targetY.is_a?(Numeric)
      @result = :invalid_params
    else
      begin
        @result = UserZone.get_attack_cost( session[:user_id], targetX, targetY )
      rescue
        @result = :database_error
      end
    end

    respond_to do |format|
      format.xml { render :layout => false }
    end
  end

  ## @result    amount of turns as an integer
  ##        :invalid_params
  def get_expand_cost
    targetX = Float(params[:targetX]).to_i rescue false
    targetY = Float(params[:targetY]).to_i rescue false

    if !targetX.is_a?(Numeric) || !targetY.is_a?(Numeric)
      @result = :invalid_params
    else
      @result = GameRules::TURNS_CONSUMED_PER_EXPAND
    end

    respond_to do |format|
      format.xml { render :layout => false }
    end
  end

  ## Build a jamming tower at the given zone.
  ## Parameters
  ##     :targetX, :targetY
  ## Return values:
  ## @result    hash with :czones and :time
  ##        :user_auth_error
  ##        :database_error
  ##        :invalid_parameters
  ##        :zone_not_owned
  ##        :already_jtower
  ##        :insufficient_turns
  def build_jamming_tower
    targetX = Float(params[:targetX]).to_i rescue false
    targetY = Float(params[:targetY]).to_i rescue false

    if !targetX.is_a?(Numeric) || !targetY.is_a?(Numeric)
      @result = :invalid_parameters
    else
      begin
        @result = UserZone.build_jamming_tower( session[:user_id], targetX, targetY )
      rescue
        @result = :database_error
      end
    end

    respond_to do |format|
      format.xml { render :layout => false }
    end
  end

  ## Parameters:
  ##    :targetX, :targetY
  ## Return values:
  ## @result    Hash with :nextsoldier, :artillery, :bunker, :jamming, :attackcost, :expandcost, :ctime
  ##         :invalid_parameters
  ##        :user_auth_error
  ##        :database_error
  def get_costs_at_location
    targetX = Float(params[:targetX]).to_i rescue false
    targetY = Float(params[:targetY]).to_i rescue false

    if !targetX.is_a?(Numeric) || !targetY.is_a?(Numeric)
      @result = :invalid_parameters
    elsif User.find_by_id( session[:user_id] ) == nil
      @result = :user_auth_error
    else
      begin
        @result = {}

        tZone = Zone.get_zone_at( targetX, targetY )
        #if tZone == nil
        @result[:expandcost] = GameRules::TURNS_CONSUMED_PER_EXPAND
        if tZone.user_id != session[:user_id]
          retval = UserZone.get_attack_cost( session[:user_id], targetX, targetY )
          if retval.class != Symbol
            @result[:attackcost] = retval
          end
        end

        @result[:bunker]     = GameRules::COST_BUNKER
        @result[:artillery]    = GameRules::COST_ARTILLERY
        @result[:jamming]     = GameRules::COST_JAMMING_TOWER
        @result[:nextsoldier]  = UserZone.peek_soldier_train_results( session[:user_id], 1 )
        @result[:ctime]      = Time.now
      rescue
        @result = :database_error
      end
    end

    respond_to do |format|
      format.xml { render :layout => false }
    end
  end

  ## Sets the P2P id string on the logged in user.
  ## @result    User object
  ##        :invalid_param
  ##        :database_error
  ##        :user_auth_error
  def put_id
    idStr = params[:idStr]

    if idStr == nil
      @result = :invalid_param
    else
      begin
        @result = User.find_by_id( session[:user_id] )
        if @result == nil
          @result = :user_auth_error
        else
          @result.p2pid      = idStr
          @result.p2pid_timestamp  = Time.now
          @result.save()
        end
      rescue
        @result = :database_error
      end
    end

    respond_to do |format|
      format.xml { render :layout => false }
    end
  end

  ## Retrieves the P2P id string and stuff.
  ## @result    User object.
  ##        :user_auth_error
  ##        :database_error
  def get_id

    begin
      @result = User.find_by_id( session[:user_id] )
      @result = :user_auth_error if @result == nil
    rescue
      @result = :database_error
    end

    respond_to do |format|
      format.xml { render :layout => false }
    end
  end


   ##change the viewport
   def viewport_change
       offsetX = Float(params[:offsetX]).to_i rescue false
       offsetY = Float(params[:offsetY]).to_i rescue false
       @user = User.find_by_id(session[:user_id])
       if @user
           @user.viewport_x += offsetX
           @user.viewport_y += offsetY
           if @user.viewport_x < 0
               @user.viewport_x = 0
           end
           if @user.viewport_y < 0
               @user.viewport_y = 0
           end
           if not @user.save_wrapup
               logger.info("viewport_change_fail:#{@user.viewport_x}, #{@user.viewport_y}")
               flash[:notice]    			= @user.errors.full_messages

           end
       end
       redirect_to(:controller => 'zones', :action => 'index')
   end
end