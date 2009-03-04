class GameController < ApplicationController

	# Methods for Pages
	# =================

	def index
		@user = User.find_by_id(session[:user_id])
	end

	# Methods for Flash Applet to grab info with.
	# ===========================================

	## Returns the positions of all the zones the given user can expand into.
	## Return values:
	## @result		Array of hash objects with :x and :y parameters for integer zone coordinates.
	## @error		:user_not_found
	##				:database_error
	def get_expandable_zones
		begin
			user 	= User.find_by_id( session[:user_id] )
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
	## @result:		Hash with :result, :time and array of potentially altered zones in :czones	
	## 				:invalid_defending_zone		<- No zone at that position.
	## 				:user_lookup_error			<- Could not find attacking or defending user.
	## 				:no_attackers				<- No adjacent zones by which to attack with!
	## 				:database_error				<- Some sort of database error.
	##				:invalid_params				<- Parameters are not good.
	##				:same_user					<- Attempting to attack self.
	##				:not_enough_soldiers		<- Attacker doesn't have enough soldiers.	
	def attack_zone
		if !params[:targetX].is_a?(Numeric) || !params[:targetY].is_a?(Numeric)
			@result = :invalid_params
		else
			begin
				@result = UserZone.attack_zone( session[:user_id], params[:targetX].to_i, params[:targetY].to_i )
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
	## @result:  	true           				<- Successful expansion!
	## 				:user_auth_error			<- User authentication error.																7
	## 				:zone_already_owned			<- The zone is already owned by a player.                                                   8
	## 				:not_enough_turns			<- The user doesn't have enough turns to do this.                                           9
	## 				:zone_not_touching			<- The target zone is not touching the player's territory ( if it's not their first. )      10
	## 				:database_error				<- Database error!
	##              :not_enough_soldiers		<- Not enough adjacent soldiers to take the zone.
	def expand_into_zone
		@result = UserZone.expand_into_zone( session[:user_id], params[:targetX].to_i, params[:targetY].to_i )
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
	## @result:		:invalid_params
	##				:database_error
	## 				Array of Zone objects!
	def get_zone_data

		# Make sure the parameters are valid!
		# -----------------------------------

		if !params[:min_x].is_a?(Numeric) || !params[:max_x].is_a?(Numeric) || !params[:min_y].is_a?(Numeric) || !params[:max_y].is_a?(Numeric)
			@result = :invalid_params
		else
			begin
				# Get the zones!
				# --------------

				@userid = session[:user_id]
				@result = Zone.find_zones_in_view_xml( params[:min_x], params[:max_x], params[:min_y], params[:max_y] )
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
	## @result		Array of Zone objects!
	##				:database_error
	##				:user_not_found
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
	## Paramters:	implicit session data.
	## Return values
	## @result		Amount of soldiers you'd get!
	##				:invalid_param					<- No such user! Or DB error.
	def peek_train_soldiers
		@result = UserZone.peek_soldier_train_results( session[:user_id], 1 )
		respond_to do |format|
			format.xml { render :layout => false}
		end
	end

	## Trains 1 turn worth of soldiers at a given location.
	## Parameters:
	##		:targetX, targetY
	## Returns values:
	## @result		Hash with :trained, :newcountatzone, :newtotal, :nextup
	##  			:database_error				<- Error, couldn't save.
	##  			:invalid_parameter			<- Error, bad params.
	##  			:not_enough_turns			<- Error, not enough turns.
	##				:user_auth_error			<- Error, couldn't find user.
	##				:no_such_zone 				<- If the zone doesn't belong to anyone
	##				:user_zone_mismatch			<- Zone isn't owned by the given player.
	def train_soldiers

		#if params[:targetX].is_a?(Numeric) || params[:targetY].is_a?(Numeric)
		#	@result = :invalid_parameter
		#else
			begin
				@result = UserZone.train_soldiers( session[:user_id], params[:targetX], params[:targetY] )
			rescue
				@result = :database_error
			end
		#end
		
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
	## @result:		:invalid_params
	##				:database_error
	## 				Zone object in @result, user_id or nil in @userid!
	def get_single_zone_info
    	if !params[:targetX].is_a?(Numeric) || !params[:targetY].is_a?(Numeric)
			@result = :invalid_params
		else
			begin
				@userid = session[:user_id]
				@result = Zone.get_zone_at( params[:targetX], params[:targetY] )
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
	## 		:sourceX, :sourceY -> :targetX, :targetY, :count
	## Return value:
	## @result		hash with :czones and :time
	##				:user_auth_error
	##				:database_error
	##				:not_enough_soldiers
	##				:must_remain_one
	##				:zones_not_owned
	##				:zones_not_adjacent
	##				:invalid_parameters
	##				:not_enough_turns
	def move_soldiers
		if !params[:targetX].is_a?(Numeric) || !params[:targetY].is_a?(Numeric) ||
		   !params[:sourceX].is_a?(Numeric) || !params[:sourceY].is_a?(Numeric) || !params[:count].is_a?(Numeric)	
			@result = :invalid_parameters
		else
			begin
				@result = UserZone.move_soldiers( session[:user_id], params[:targetX], params[:targetY], params[:sourceX], params[:sourceY], params[:count] )
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
	end
	
	## Similar to soldiers. Moves em!
	## Parameters:
	## 		:sourceX, :sourceY -> :targetX, :targetY
	## Return values:
	## @result		hash with :czones and :time
	##				:user_auth_error
	##				:database_error
	##				:no_artillery_at_source
	##				:artillery_at_target
	##				:zones_not_owned
	##				:zones_not_adjacent
	##				:invalid_parameters
	##				:not_enough_turns
	def move_artillery
		if !params[:targetX].is_a?(Numeric) || !params[:targetY].is_a?(Numeric) ||
		   !params[:sourceX].is_a?(Numeric) || !params[:sourceY].is_a?(Numeric)
			@result = :invalid_parameters
		else
			begin
				@result = UserZone.move_artillery( session[:user_id], params[:targetX], params[:targetY], params[:sourceX], params[:sourceY] )
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
	## 		:targetX, :targetY
	## Return values:
	## @result		hash with :czones and :time
	##				:user_auth_error
	##				:database_error
	##				:invalid_parameters
	##				:zone_not_owned
	##				:already_artillery
	##				:insufficient_turns
	def build_artillery
		if !params[:targetX].is_a?(Numeric) || !params[:targetY].is_a?(Numeric)
			@result = :invalid_parameters
		else
			begin
				@result = UserZone.build_artillery( session[:user_id], params[:targetX], params[:targetY] )
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
	## 		:targetX, :targetY
	## Return values:
	## @result		hash with :czones and :time
	##				:user_auth_error
	##				:database_error
	##				:invalid_parameters
	##				:zone_not_owned
	##				:already_bunker
	##				:insufficient_turns
	def build_bunker
		if !params[:targetX].is_a?(Numeric) || !params[:targetY].is_a?(Numeric)
			@result = :invalid_parameters
		else
			begin
				@result = UserZone.build_bunker( session[:user_id], params[:targetX], params[:targetY] )
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
	## 		:userid or nil if want to get own data ( needs session info in that case. )
	## Returns:
	##		User object
	##		:invalid_param
	##		:no_user
	def get_user_info
		if !params[:userid].is_nil? && !params[:userid].is_a?(Numeric)
			@result = :invalid_param
		else
			@userid = params[:userid]
			@result = User.find_by_id( @userid )
			if @result == nil
				@result = :no_user
			end
		end

		respond_to do |format|
			format.xml { render :layout => false }
		end
	end

	## Sets the viewport location on the user object for reference.
	## Parameters:
	## 		:x, :y
	## Return values:
	## @result		true
	##				:user_auth_error
	##				:invalid_parameters
	##				:database_error
	def set_viewport_data
		if !params[:x].is_a?(Numeric) || !params[:y].is_a?(Numeric)
			@result = :invalid_parameters
		else
			begin
				user = User.find_by_id( session[:user_id] )
				if user.is_nil?
					@result = :user_auth_error
				else
					user.change_viewport( params[:x], params[:y] )
					user.save()
					@result = true
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
	##		:targetX, :targetY
	## Return values
	## @result		amount of turns as an integer
	##				:user_auth_error
	##				:database_error
	##				:invalid_params
	##				:invalid_target
	##				:cant_attack_zone
	def get_attack_cost
		if !params[:targetX].is_a?(Numeric) || !params[:targetY].is_a?(Numeric)
			@result = :invalid_params
		else
			begin
				@result = UserZone.get_attack_cost( session[:user_id], params[:targetX], params[:targetY] )
			rescue
				@result = :database_error
			end
		end

		respond_to do |format|
			format.xml { render :layout => false }
		end
	end

	## @result		amount of turns as an integer
	##				:invalid_params
	def get_expand_cost
		if !params[:targetX].is_a?(Numeric) || !params[:targetY].is_a?(Numeric)
			@result = :invalid_params
		else
			@result = GameRules::TURNS_CONSUMED_PER_EXPAND
		end

		respond_to do |format|
			format.xml { render :layout => false }
		end
	end
end