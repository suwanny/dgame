# This file defines all the constants/functions/etc that are used as tweakable parameters for the game.
# =====================================================================================================

class GameRules

  # Constants
  # =========

  TURNS_GAINED_PER_HOUR        = 8
  MINUTES_PER_TURN                    = 60 / TURNS_GAINED_PER_HOUR
  MAX_TURN_STORAGE          = 250    # The number of turns a user can save up.
  MAX_TURNS_GAINED_PER_LOGIN      = 5000    # (Deprecated)
  DEFAULT_STARTING_SOLDIER      = 50
  DEFAULT_STARTING_TURNS        = 50
  TURNS_CONSUMED_PER_ATTACK           = 50     # The number of turns used to expand a zone
  TURNS_CONSUMED_PER_EXPAND      = 10     # The number of turns used to expand a zone
  TURNS_CONSUMED_PER_MOVE        = 10     # The number of turns used to perform a move
  TOTAL_SOLDIERS_LOST_IN_BATTLE       = 10    # (Deprecated)
  TURNS_PER_SOLDIER                   = 20    # Training Cost. (StatesGame)
  ZONE_SIZE              = 0.005    # Degrees Latitude/Longitude square.
  ZONE_COUNT_X            = 360 / ZONE_SIZE
  ZONE_COUNT_Y            = 180 / ZONE_SIZE
  ATTACK_POWER_SOLDIER        = 1
  ATTACK_POWER_ARTILLERY        = 50
  BUNKER_DEFENSE_MULTIPLIER      = 2
  ATTACK_MAX_UNIT_LOSS_PERCENT    = 0.3    # Maximum percent of soldiers lost for the attackers.
  ATTACK_MAX_UNIT_FLEE_PERCENT    = 0.2    # Maximum percent of defending soldiers that will flee after their zone is taken over.
  ATTACK_ARTILLERY_HIJACK_PERCENT    = 0.2    # Chance of taking over an artillery!

  ZONE_EXPANDABLE_AREA_OFFSETS    = [ [0, 1], [0, -1], [1, 0], [-1, 0] ]

  # Functions
  # =========

  def game_zone_explore_cost( userobj, x, y )
    return TURNS_CONSUMED_PER_EXPAND
  end

  ## Given a zone by integer position X/Y, this function returns the latitude/longitude of that zone.
  ## Input is the x/y integer representation of the zone, which goes from 0 to ZONE_COUNT_X-1 along X
  ## and 0 to ZONE_COUNT_Y-1 along Y.
  ## Output is the latitude/longitude of the NORTH-WEST CORNER of the zone. { :lat, :long }
  ## Note that (0,0) on the map is in the northwest corner of the world map in lat/long space, and
  ## will translate to (0,+90) lat/long.

  def game_zone_int_to_latlong( x, y )
    raise "x not in range" if x < 0 || x >= ZONE_COUNT_X
    raise "y not in range" if y < 0 || y >= ZONE_COUNT_Y
    lat    = 90 - y.floor * ZONE_SIZE
    long  = x.floor * ZONE_SIZE

    return { :lat => lat, :long => long }
  end

  ## Reverse of the previous function.
  ## Inputs are latitude from +90 to -90+ZONE_SIZE and longitude from 0 to 360-ZONE_SIZE.

  def game_zone_latlong_to_int( lat, long )
    raise "latitude is not in range"  if lat > 90 || lat < -90+ZONE_SIZE
    raise "longitude is not in range"  if long < 0 || long > 360-ZONE_SIZE
    x  = long / ZONE_SIZE
    y  = ( 90 - lat ) / ZONE_SIZE

    return { :x => x.floor, :y => y.floor }
  end

  ## This formula handles the attacking formula. The parameters are:
  ## - attacking_zones 	<- Array of Zone objects that will attack with soldiers.
  ## - support_attackers 	<- Array of Zone objects that will attack with artillery ( if they have one )
  ## - defending_zone		<- Zone object that will defend with soldiers!
  ## - support_defenders	<- Array of Zone objects that will assist the defense with artillery ( if they have one )
  ## This function does not alter any zone data. It merely looks at the zone data and returns results.
  ##
  ## The results look like a hash with the following values:
  ## - :result 			=> true or false for succeeded attack or failed attack.
  ## - :dloss				=> amount of units the defenders lose
  ## - :dflee				=> amount of defending units that escape into surrounding zones ( or are killed if no such zones, but that's not for this to know about.)
  ## - :dartillery    	=> true if the defending zone had an artillery on it and it was captured.
  ## - :aloss#			=> (FUTURE) soldiers lost from attacking zone # - aloss1, aloss2, aloss3, aloss4.
  ## - :aloss				=> total amount of soldiers the attacking side loses.

  def game_attack_formula( attacking_zones, support_attackers, defending_zone, support_defenders )

    # Get the user data.
    # ==================

    auser = User.find_by_id( attacking_zones[0].user_id )
    duser = User.find_by_id( defending_zone.user_id )

    # Gather the attacking strength
    # =============================

    modifier   = ( attacking_zones.size() + 1 ) / 2  # Multiplier for amount you have the enemy surrounded.
    apower     = ( ATTACK_POWER_SOLDIER * attacking_zones.size() *  auser.total_soldiers / auser.total_zones )
    # Temporary calculation until we use soldier count per zone.

    #apower		= 0				# Temporarily commented out until we're using soldier count for each zone.
    #for z in attacking_zones
    #	apower	+= z.soldiers
    #end

    apower    *= modifier

    for z in support_attackers
      if z.artillery == true
        apower += ATTACK_POWER_ARTILLERY
      end
    end

    # Gather the defending strength
    # =============================

    #dpower		= ATTACK_POWER_SOLDIER * defending_zone.total_soldiers	# Same reason.

    dpower    = duser.total_soldiers / duser.total_zones
    if duser.bunker
      dpower *= BUNKER_DEFENSE_MULTIPLIER
    end

    for z in support_defenders
      if z.artillery == true
        dpower += ATTACK_POWER_ARTILLERY
      end
    end

    # Run some formula to figure out what happens.
    # ============================================

    srand()
    baseP   = [50 - 4*dpower/20, 10 ].max
    prop  = ( BaseP + apower / dpower ) / 10
    results  = {}

    if rand() > prop then

      # A successful attack! Decide what happens!
      # We'll need to determine how many defending soldiers flee and how many attackers are lost.
      # =========================================================================================

      dSoldiers    = duser.total_soldiers
      aSoldiers    = auser.total_soldiers
      fleeCount     = ( dSoldiers * ATTACK_MAX_UNIT_FLEE_PERCENT * rand() ).floor
      artilleryGet  = rand() < ATTACK_ARTILLERY_HIJACK_PERCENT if defending_zone.artillery == true
      aLosses      = [ aSoldiers-2, ( aSoldiers * ATTACK_MAX_UNIT_LOSS_PERCENT * rand() ).floor ].max     # Make sure the user still has 2 soldiers left.

      # Set the Results.
      # ================

      results[:result]     = true
      results[:dloss]      = dSoldiers - fleeCount
      results[:dflee]      = fleeCount
      results[:dartillery]  = artilleryGet
      results[:aloss]      = aLosses

    else

      # Defense stands strong! Decide what happens!
      # Basically we need to decide how many units the offense and defense will lose.
      # =============================================================================

      srand()
      aLPerc  = rand() * ATTACK_MAX_UNIT_LOSS_PERCENT      # Percent modifier that the attacker will lose from the attack: Basically 30% * rand(0 to 1)
      dLPerc  = rand() * aLPerc                 # Percent modifier that the defender will lose from the attack: The one from before * rand(0 to 1)

      aLoss   = [ ( auser.total_soldiers * aLPerc ).floor, auser.total_soldiers - 1 ].min    # So make sure attacker will have at least one soldier left ( so they can occupy their own zone still. )
      dLoss  = [ ( duser.total_soldiers * dLPerc ).floor, duser.total_soldiers - 1 ].min   # So make sure duser will have at least one soldier left.

      # Set the results.
      # ================

      results[:dloss]   = dLoss
      results[:aloss]   = aLoss
      results[:result]  = false

    end

    # Return the results
    # ==================

    return results

  end

end