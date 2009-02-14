require 'gamerules'

class GameController < ApplicationController

  # Methods for Pages
  # =================

  def index
    @user = User.find_by_id(session[:user_id])
  end

  # Methods for Flash Applet to grab info with.
  # ===========================================

  ## Returns the positions of all the zones the given user can expand into.

  def get_expandable_zones
    @ezones = Zone.get_expandable_zones( session[:user_id] )
  end

  ## User attacks the given zone. If successful, the user gains the zone. Returns different information if:
  ## - The attack succeeded.
  ## - The attack failed because the defense held.
  ## - The attack failed because the attacker only has one soldier attacking and he can't capture another zone, Risk style.
  ## - It didn't work because of some database error.
  ## - It didn't work because of parameter error or user authentication error.
  ## Params:
  ## :targetX, :targetY, implicit session data.
  #

  def attack_zone

    # Grab the users and the defending zone.
    # -------------------------------------

    auser   = User.find_by_id( session[:user_id] )
    dzone  = Zone.find( :first, :conditions => { :x => params[:targetX], :y => params[:targetY] } )
    if dzone == nil
      @error = :invalid_defending_zone
      return
    end

    duser  = User.find_by_id( dzone.user_id )

    if duser == nil || auser == nil
      @error = :user_lookup_error
      return
    end

    # Find all the attacking zones. Get candidate attacking zones, the sort into directly
    # attacking and support. Pruning support if they have artillery or not will be left to the
    # formula. Later I'll want to add the ability for allies to help here. ( With a special
    # case of an ally attacking an ally. )
    # ----------------------------------------------------------------------------------------

    cazones  = Zone.get_zones_by_user_in_area( auser.id, dzone.x+1, dzone.x-1, dzone.y+1, dzone.y-1 );
    if cazones.size() <= 0
      @error = :no_attackers
      return
    end

    azones    = []
    azones_sup  = []

    for z in cazones
      if z.x == dzone.x || z.y == dzone.y
        azones << z              # Attacking z zone is connected and will attack with soldiers!
      elsif z.artillery == true
        azones_sup << z            # Attacking z zone is on diagonal and can do artillery strike if it has one!
      end
    end

    # Find any supporting defending zones.
    # Later we'll want to look for supporting allied zones.
    # -----------------------------------------------------

    dzones    = Zone.get_zones_by_user_in_area( duser.id, dzone.x+1, dzone.x-1, dzone.y+1, dzone.y-1 );
    dzones_sup  = []

    for z in cazones
      if ( z.x != dzone.x || z.y != dzone.y ) && dzone.artillery == true
        dzones_sup << z
      end
    end

    # Run the Attacking Formula and handle the results.
    # At this junction this means changing the owner of the zone if need be,
    # and lowering the amount of soldiers for both users. Later it will involve
    # moving one soldier into the zone, fleeing defending soldiers into neighboring
    # zones ( or dying if none such exist ), and taking over an artillery if one
    # gets taken over!
    # ----------------------------------------------------------------------------

    results = game_attack_formula( azones, azones_sup, dzone, dzones_sup )
    auser.total_soldiers  -= results[:aloss]
    duser.total_soldiers  -= results[:dloss]
    dzone.user_id      = auser.id      if results[:result] == true

    begin
      User.transaction do
        auser.save()
        duser.save()
        dzone.save()
      end
    rescue
      @error = :database_or_constraint_error
      return
    end

    # Return a successful (no exceptions) attack.
    # -------------------------------------------

    @success = true

  end

  ## User expands into the given zone. Returns different information if:
  ## - It worked
  ## - It didn't work because someone already owns that zone.
  ## - It didn't work because of some database error.
  ## - It didn't work because of parameter error or user authentication error.
  ## Parameters are:
  ## - :targetX, :targetY
  ##
  ## Return values:
  ## @error: 		:user_auth_error
  ##				:zone_already_owned
  ##				:not_enough_turns
  ##				:zone_not_touching
  ##				:database_error
  ## @success:	true

  def expand_into_zone

    # Make sure we have a user whom can expand.
    # -----------------------------------------

    user   = User.find_by_id( session[:user_id] )
    if user.nil?
      @error = :user_auth_error
      return
    end

    # Check to see if the zone is already owned or not
    # ------------------------------------------------

    targetX  = params[:targetX]
    targetY  = params[:targetY]
    tzone   = Zone.get_zone_at( targetX, targetY )
    if !tzone.nil?  # So we want it to be nil.
      @error = :zone_already_owned
      return
    end

    # Make sure the user has enough turns to take this zone
    # -----------------------------------------------------

    mcost   = game_zone_explore_cost( user, targetX, targetY )
    pturns  = user.peek_current_turn_count()
    if mcost > pturns
      @error = :not_enough_turns
      return
    end

    # Make sure the user owns a zone adjacent to this one.
    # ----------------------------------------------------

    adj_ok = false
    for z in Zone.get_zones_by_user_in_area( user.id, targetX+1, targetX-1, targetY+1, targetY-1 )
      if z.x == targetX || z.y == targetY
        adj_ok = true
        break
      end
    end

    if !adj_ok
      @error = :zone_not_touching
      return
    end

    # Make sure there is an adjacent zone with one soldier to move in. - FUTURE
    # -------------------------------------------------------------------------

    # Success! The zone can be claimed by the user.
    # ---------------------------------------------

    user.spend_turns( mcost )
    user.total_zones += 1
    z = Zone.new( :x <= targetX, :y <= targetY, :user_id <= user.id )

    begin
      User.transaction do
        user.save()
        z.save()
      end
    rescue
      @error = :database_error
      return
    end

    # Return a successful expansion.
    # ------------------------------

    @success = true

  end

  ## Returns all zone data in a given bounding box. Information will be passed into @zones and
  ## it will be an array of Zone objects.
  ## Params:
  ## :max_x, :min_x, :max_y, :min_y, no session data needed. X and Y is integer X/Y, not lat/long
  ##
  ## Return values:
  ## @error: 		:invalid_params
  ##				:database_error
  ## @success:	true

  def get_zone_data

    # Make sure the parameters are valid!
    # -----------------------------------

    if !params[:min_x].is_a?(Numeric) || !params[:max_x].is_a?(Numeric) || !params[:min_y].is_a?(Numeric) || !params[:max_y].is_a?(Numeric)
      @error = :invalid_params
      return
    end

    # Get the zones!
    # --------------

    begin
      @zones = Zone.find_zones_in_view_xml( params[:min_x], params[:max_x], params[:min_y], params[:max_y] )
    rescue
      @error = :database_error
      return
    end

    # Success!
    # --------

    @success = true
  end

  ## Returns all the zones that can be attacked by the user.
  ## This function will return an array of Zone objects ( for the view to format as it likes )

  def get_attackable_zones

  end

  ## Returns # of soldiers the player would get by spending the given # of turns.

  def peek_train_soldiers

  end

  ## Trains soldiers by spending a given # of turns. Returns information if this:
  ## - Worked.
  ## - Failed because not enough turns.
  ## - Failed because of database error.
  ## - Failed because of user authentication error.

  def train_soldiers

  end

end