
## So this class isn't ActiveRecord, and it's not connected to any database table. This only
## encapsulates logic that _should_ be in the model into the model section of Rails. Woo!
class UserZone

	public

		## User attacks the given zone. If successful, the user gains the zone. Returns:
		##
		## true						<- Successful attack! The zone has been taken.
		## false					<- Unsuccessful attack! The zone was successfully defended!
		## :invalid_defending_zone	<- No zone at that position.
		## :same_user				<- Can't have a player attack himself.
		## :user_lookup_error		<- Could not find attacking or defending user.
		## :no_attackers			<- No adjacent zones by which to attack with!
		## :database_error			<- Some sort of database error.
		## :not_enough_soldiers		<- Attacker does not have enough soldiers to take the zone if successful.
		def self.attack_zone( a_user_id, targetX, targetY )

            # Grab the users and the defending zone.
			# -------------------------------------

			auser	= User.find_by_id( a_user_id )
            dzone	= Zone.find( :first, :conditions => { :x => targetX, :y => targetY } )
            return :invalid_defending_zone 	if dzone == nil						# Target zone is not owned by anyone.

			duser 	= User.find_by_id( dzone.user_id )
			return :user_lookup_error 		if duser == nil || auser == nil		# Can't find either user.                         	
            return :same_user 				if a_user_id == dzone.user_id  		# Can't attack self.

			# Find all the attacking zones. Get candidate attacking zones, the sort into directly
			# attacking and support. Pruning support if they have artillery or not will be left to the
			# formula. Later I'll want to add the ability for allies to help here. ( With a special
			# case of an ally attacking an ally. )
			# ----------------------------------------------------------------------------------------

			cazones  = Zone.get_zones_by_user_in_area( auser.id, dzone.x-1, dzone.x+1, dzone.y-1, dzone.y+1 );
			return :no_attackers 			if cazones.size() <= 0				# Return error if the user can't actually attack this zone!

			azones    	= []
			azones_sup  = []

            # 1. The U, D, L, R zones can help attacking (azone)
            # 2. The artillery zone in the diagonal positions can also help attacking (azones_sup)
            
			for z in cazones
				if z.x == dzone.x || z.y == dzone.y
					azones << z              					# Attacking z zone is connected and will attack with soldiers!
				elsif z.artillery == true
					azones_sup << z            					# Attacking z zone is on diagonal and can do artillery strike if it has one!
				end
			end
            return :no_attackers if azones.size() <= 0			# Return error if the user can't actually attack this zone!

			# Find any supporting defending zones.
			# Later we'll want to look for supporting allied zones.
            # 1. All the artillery zones in the 3*3 grid (except itself) can defend the zone (dzones_sup)
			# -------------------------------------------------------------------------------------------

			dzones		= Zone.get_zones_by_user_in_area( duser.id, dzone.x - 1, dzone.x + 1, dzone.y - 1, dzone.y + 1 );
			dzones_sup	= []

			for z in dzones
				if ( z.x != dzone.x || z.y != dzone.y ) && dzone.artillery == true
					dzones_sup << z
				end
			end

			# Make sure the user has enough turns to attack.
			# ----------------------------------------------

			asoldiercount 	= 0
			dsoldiercount 	= dzone.soldiers

			for a in azones
				asoldiercount += a.soldiers
			end

			turncost		= GameRules::game_zone_attack_cost( asoldiercount, dsoldiercount )
			return :turns_not_enough 		if auser.peek_current_turn_count() < turncost
			return :not_enough_soldiers		if asoldiercount <= azones.size()

			# Run the Attacking Formula and handle the results.
			# At this junction this means changing the owner of the zone if need be,
			# and lowering the amount of soldiers for both users. Later it will involve
			# moving one soldier into the zone, fleeing defending soldiers into neighboring
			# zones ( or dying if none such exist ), and taking over an artillery if one
			# gets taken over!
			# ----------------------------------------------------------------------------

			results 				= GameRules.game_attack_formula( azones, azones_sup, dzone, dzones_sup )
			aLoss					= results[:aloss]
			dLoss					= results[:dloss]

			RAILS_DEFAULT_LOGGER.debug "aLoss = " + aLoss.to_s
			RAILS_DEFAULT_LOGGER.debug "dLoss = " + dLoss.to_s
			RAILS_DEFAULT_LOGGER.debug "Prev Total Soldiers Attacker = " + auser.total_soldiers.to_s
			RAILS_DEFAULT_LOGGER.debug "Prev Total Soldiers Defender = " + duser.total_soldiers.to_s
			RAILS_DEFAULT_LOGGER.debug "Prev Total Zones Attacker = " + auser.total_zones.to_s
			RAILS_DEFAULT_LOGGER.debug "Prev Total Zones Defender = " + duser.total_zones.to_s
			RAILS_DEFAULT_LOGGER.debug "Prev Score Attacker = " + auser.score.to_s
			RAILS_DEFAULT_LOGGER.debug "Prev Score Defender = " + duser.score.to_s

			auser.total_soldiers 	= auser.total_soldiers - aLoss
			duser.total_soldiers  	= duser.total_soldiers - dLoss
            auser.spend_turns( turncost )

			RAILS_DEFAULT_LOGGER.debug "this is a test"

			alteredzones			= []		# Get a list of all the zones that were altered in some manner.
			alteredzones << dzone
			for a in azones
				alteredzones << a
			end

			if results[:result] == true

				RAILS_DEFAULT_LOGGER.debug "ATTACK VICTORY"

				# Transfer the zone to the attacker.
				# ----------------------------------

				dzone.user_id      	= auser.id						# Transfer this to the attacker.
				dzone.soldiers		= 1								# Move one soldier into the acquired zone.
				auser.total_zones 	= auser.total_zones + 1			# Add one zone to the attacking user
                duser.total_zones 	= duser.total_zones - 1			# Subtract one zone from the defender.
				auser.score			= auser.score + dzone.score
				duser.score			= duser.score - dzone.score

				dzone.bunker 		= false							# Always kill the bunker.

				if dzone.artillery == true && results[:dartillery] == false
					dzone.artillery = false            				# Sometimes take the artillery
				end

				if dzone.jamming
					auser.jammingcount	= auser.jammingcount + 1	# Always take the jamming tower.
					duser.jammingcount 	= duser.jammingcount - 1
				end

				# Remove aLoss + 1 soldiers from the attacking zones, azones.
				# +1 since a soldier was moved into the zone to attack.
				# -----------------------------------------------------------

                # Xin: possible to have endless loops, should check the validity of rVal
				aRemove	= aLoss + 1
				while aRemove > 0
					for a in azones do
						if aRemove > 0
							rVal 		= [ aRemove, ( aLoss/3 ).floor, a.soldiers-1 ].min
                        	rVal 		= 1 if rVal <= 0        # added by Xin
							aRemove 	= aRemove - rVal
							a.soldiers 	= a.soldiers - rVal
						end
					end
				end

				# Add dflee units to the loser's adjacent zones. If so such zones, kill the units.
				# --------------------------------------------------------------------------------

				dFlee = results[:dflee]

				fZones = []
				for z in dzones
					if ( z.x == dzone.x ) ^ ( z.y == dzone.y )
						fZones << z
						alteredzones << z
					end
				end

				if fZones.size() == 0
			   		duser.total_soldiers -= dFlee			# Nowhere for them to run.
				else
					dLeftToFlee = dFlee
					for i in 0..( fZones.size() - 1) do       # Xin: formerly it was 0..( fZones.size())  
			   			if i == fZones.size()-1
                            if fZones[i].soldiers
							    fZones[i].soldiers += dLeftToFlee
                            else
                                fZones[i].soldiers = dLeftToFlee
                            end
						else
							rval = ( dFlee/3 ).floor
							dLeftToFlee -= rval 
                            if fZones[i].soldiers
							    fZones[i].soldiers += rval
                            else
                                fZones[i].soldiers = rval
                            end
                        end
					end
				end

			else

				RAILS_DEFAULT_LOGGER.debug "ATTACK FAILED"

				# Remove units from the attacker's attacking zones.
				# -------------------------------------------------
                # Xin: possible to have endless loops, should check the validity of rVal

				aRemove	= aLoss
				while aRemove > 0
					for a in azones do
						if aRemove > 0
							rVal 		= [ aRemove, ( aLoss/3 ).floor, a.soldiers-1 ].min
                        	rVal = 1 if rVal <= 0        # added by Xin
							aRemove 	-= rVal
							a.soldiers 	-= rVal
						end
					end
				end

				# Remove lost soldiers from the defending zone.
				# ---------------------------------------------

				dzone.soldiers -= dLoss
			end

			RAILS_DEFAULT_LOGGER.debug "After Total Soldiers Attacker = " + auser.total_soldiers.to_s
			RAILS_DEFAULT_LOGGER.debug "After Total Soldiers Defender = " + duser.total_soldiers.to_s
			RAILS_DEFAULT_LOGGER.debug "After Total Zones Attacker = " + auser.total_zones.to_s
			RAILS_DEFAULT_LOGGER.debug "After Total Zones Defender = " + duser.total_zones.to_s
			RAILS_DEFAULT_LOGGER.debug "After Score Attacker = " + auser.score.to_s
			RAILS_DEFAULT_LOGGER.debug "After Score Defender = " + duser.score.to_s
                                   	 
			begin
				Zone.transaction do

					tstamp = "\"" + Time.now.strftime( "%Y-%m-%d %H:%M:%S" ) + "\""

					for z in azones do
						RAILS_DEFAULT_LOGGER.debug "========= Save an attacking zone"
						rawsql = 'UPDATE zones SET soldiers = ' + z.soldiers.to_s +
											    #', update_at = ' + tstamp + 
												' WHERE id = ' + z.id.to_s
						RAILS_DEFAULT_LOGGER.debug "Do: " + rawsql
						ActiveRecord::Base.connection.execute( rawsql )
						#z.save! # Good lord, this doesn't work. Raw SQL is the only hope.
						RAILS_DEFAULT_LOGGER.debug "========= Done"
					end

					if results[:result]
						for b in dzones
							if ( b.x == dzone.x && b.y != dzone.y ) || ( b.x != dzone.x && b.y == dzone.y ) # XOR
								RAILS_DEFAULT_LOGGER.debug "========= Save a defending zone"
								rawsql = 'UPDATE zones SET soldiers = ' + b.soldiers.to_s +
														#', update_at = ' + tstamp +
														', user_id = ' + b.user_id.to_s +
										 				', jamming = ' + ( b.jamming ? 1 : 0 ).to_s +
														', bunker = ' + ( b.bunker ? 1 : 0 .to_s) +
														', artillery = ' + ( b.artillery ? 1 : 0 ).to_s +
														' WHERE id = ' + b.id.to_s
								ActiveRecord::Base.connection.execute( rawsql )
								#b.save!
								RAILS_DEFAULT_LOGGER.debug "========= Done"
							end
						end
					end

					RAILS_DEFAULT_LOGGER.debug "========= Save dzone"
					rawsql = 'UPDATE zones SET soldiers = ' + dzone.soldiers.to_s +
													#', update_at = ' + tstamp +
													', user_id = ' + dzone.user_id.to_s +
													', jamming = ' + ( dzone.jamming ? 1 : 0 ).to_s +
													', bunker = ' + ( dzone.bunker ? 1 : 0 ).to_s +
													', artillery = ' + ( dzone.artillery ? 1 : 0 ).to_s +
													' WHERE id = ' + dzone.id.to_s
					ActiveRecord::Base.connection.execute( rawsql )
					#dzone.save!
					RAILS_DEFAULT_LOGGER.debug "========= Done"

					RAILS_DEFAULT_LOGGER.debug "========= Save attacking user"
					#auser.save!
					rawsql = 'UPDATE users SET total_soldiers = ' + auser.total_soldiers.to_s +
											  ', total_zones = '    + auser.total_zones.to_s +
											  ', score = '          + auser.score.to_s +
 											   ' WHERE id = ' + auser.id.to_s
					ActiveRecord::Base.connection.execute( rawsql )
					RAILS_DEFAULT_LOGGER.debug "========= Done"




					RAILS_DEFAULT_LOGGER.debug "========= Save defending user"
					rawsql = 'UPDATE users SET total_soldiers = ' + duser.total_soldiers.to_s +
											  ', total_zones = '    + duser.total_zones.to_s +
											  ', score = '          + duser.score.to_s +
 											   ' WHERE id = ' + duser.id.to_s
					ActiveRecord::Base.connection.execute( rawsql )
					#duser.save!
					RAILS_DEFAULT_LOGGER.debug "========= Done"
				end

				RAILS_DEFAULT_LOGGER.debug "Transaction complete?"
			rescue ActiveRecord::RecordInvalid => invalid
				RAILS_DEFAULT_LOGGER.debug "SOME SORT OF DATABASE ERROR LAWL"
				return :database_or_constraint_error
			end

			# Return a successful (no exceptions) attack.
			# -------------------------------------------

			RAILS_DEFAULT_LOGGER.debug "Post Transaction Total Soldiers Attacker = " + auser.total_soldiers.to_s
			RAILS_DEFAULT_LOGGER.debug "Post Transaction Total Soldiers Defender = " + duser.total_soldiers.to_s
			RAILS_DEFAULT_LOGGER.debug "Post Transaction Total Zones Attacker = " + auser.total_zones.to_s
			RAILS_DEFAULT_LOGGER.debug "Post Transaction Total Zones Defender = " + duser.total_zones.to_s
			RAILS_DEFAULT_LOGGER.debug "Post Transaction Score Attacker = " + auser.score.to_s
			RAILS_DEFAULT_LOGGER.debug "Post Transaction Score Defender = " + duser.score.to_s

			return { :result => results[:result], :time => Time.now, :czones => alteredzones,
					 :auser => auser, :duser => duser }

		end

		## Claims the target zone for the given user. Returns the given values if such and such happens:
		##
		## Hash with :time and :czones for changed zones.
		## :user_auth_error			<- User authentication error.
		## :zone_already_owned		<- The zone is already owned by a player.
		## :not_enough_turns		<- The user doesn't have enough turns to do this.
		## :zone_not_touching		<- The target zone is not touching the player's territory ( if it's not their first. )
		## :database_error			<- Database error!
		## :not_enough_soldiers		<- Not enough soldiers to take the zone.
		def self.expand_into_zone( user_id, targetX, targetY )

			# Make sure we have a user whom can expand.
			# -----------------------------------------

			user = User.find_by_id( user_id )
			return :user_auth_error if user.nil?   			# Return an error code if the user can't be found.

			# Check to see if the zone is already owned or not
			# ------------------------------------------------

			tzone = Zone.get_zone_at( targetX, targetY )
			return :zone_already_owned if !tzone.nil?  		# So we want it to be nil.

			# Make sure the user has enough turns to take this zone
			# -----------------------------------------------------

			mcost   	= GameRules::game_zone_explore_cost( user, targetX, targetY )
			pturns  	= user.peek_current_turn_count()
			return :not_enough_turns if mcost > pturns		# Return an error code if this costs more turns if the user has.

			# Make sure the user owns a zone adjacent to this one.
			# If they own no zones, then pass this test ( It's their first one )
			# Check each zone owned by the user (in a limited area), and make sure one of them is next to this zone.
			# ------------------------------------------------------------------------------------------------------

			first_zone	= false
			first_zone  = true if user.total_zones == 0

			adj_zones 	= []
			for z in Zone.get_zones_by_user_in_area( user.id, targetX - 1, targetX + 1, targetY - 1, targetY + 1)
				if z.x == targetX || z.y == targetY
					adj_zones << z
#					break    #commented out by Xin Mao: will cause bugs
				end
			end

			return :zone_not_touching if !first_zone && adj_zones.length == 0

			# Make sure there is an adjacent zone with one soldier to move in. And build
			# the list of affected zones at this juncture.
			# -------------------------------------------------------------------------

			affectedzones = []

			soldiermove = false
			for z in adj_zones do
				if z.soldiers and z.soldiers > 1
					z.soldiers -= 1   		# Move this soldier into the zone.
					affectedzones << z
					soldiermove = true
					break
				end
			end

            return :not_enough_soldiers if !first_zone && !soldiermove
#			return "not_enough_soldiers_from_" + adj_zones.size().to_s+"_adjacent_zones" if !first_zone && !soldiermove

			# Get how much the zone is worth. For right now this will just be 4+/-1/, later
			# it'll be based on population density.
			# -----------------------------------------------------------------------------

			srand()
			zoneScore = 3 + rand(3)

			# Success! The zone can be claimed by the user.
			# ---------------------------------------------

			user.spend_turns( mcost ) if !first_zone
			user.total_zones += 1
			z = Zone.new( :x => targetX, 	:y => targetY, 		:user_id => user.id,
						  :soldiers => 1, 	:bunker => false, 	:artillery => false, :jamming => false,
						  :score => zoneScore )
            if user.score == nil
                user.score = 0
            end
			user.score += zoneScore
			affectedzones << z

			user.total_soldiers = 1 if first_zone

			begin
				User.transaction do
					for a in affectedzones
						a.save()
					end
					user.save()
				end
			rescue
				return :database_error
			end

			# Return a successful expansion.
			# ------------------------------

			return { :czones => affectedzones, :time => Time.now, :user => user }

		end

		## :user_auth_error
		## :no_such_zone
		## :user_zone_mismatch
		## :not_enough_turns
		## :database_error
        def self.train_soldiers( user_id, targetX, targetY )		

			# Get the user and the target zone.
			# =================================

            user = User.find_by_id( user_id )
            return :user_auth_error 	if user.nil?

			z = Zone.get_zone_at( targetX, targetY )
			return :no_such_zone 		if z.nil?
			return :user_zone_mismatch 	if z.user_id != user_id

           
    		return :not_enough_turns 	if user.peek_current_turn_count() < 1
    		nscount             		= GameRules::get_soldier_train_count( user.total_soldiers, 1 )    	# Grab the amount of soldiers that will be trained.
    		user.total_soldiers 		+= nscount                                                                	# Increase this amount of soldiers.
			if z.soldiers
                z.soldiers 					+= nscount
            else
                z.soldiers = nscount
            end   
			user.spend_turns( 1 )

			begin
				User.transaction do
					z.save()
					user.save()
				end
			rescue
				return :database_error
			end

			# Compile the results
			# ===================

    		return { :czone => z,						:time => Time.now,
					 :trained => nscount, 				:newcountatzone => z.soldiers,
					 :newtotal => user.total_soldiers, 	:nextup => GameRules::get_soldier_train_count( user.total_soldiers, 1 ),
					 :user => user }

        end

		def self.peek_soldier_train_results( user_id, turns )

			user = User.find_by_id( user_id )
			return :invalid_param if user.nil?

			return GameRules::get_soldier_train_count( user.total_soldiers, turns )
		end

		## Return value:
		## @result		true
		##				:user_auth_error
		##				:database_error
		##				:not_enough_soldiers
		##				:must_remain_one
		##				:zones_not_owned
		##				:zones_not_adjacent
		##				:invalid_parameters
		##				:not_enough_turns
		def self.move_soldiers( userid, targetX, targetY, sourceX, sourceY, count )

			# Make sure the zones are next to each other.
			# ===========================================

			#return :zones_not_adjacent if ( abs( targetX - sourceX ) == 1 ) ^ ( abs( targetY - sourceY ) == 1 )

			# Make sure there's enough turns to do this.
			# ==========================================

			user = User.find_by_id( userid )
			return :user_auth_error  if user.nil?
			return :not_enough_turns if user.peek_current_turn_count() < GameRules::COST_MOVE_SOLDIERS

			# Get the zones
			# =============

			zoneTarget	= Zone.get_zone_at( targetX, targetY )
			zoneSource	= Zone.get_zone_at( sourceX, sourceY )

			return :zones_not_owned if zoneTarget.nil? || zoneSource.nil?
			return :zones_not_owned if zoneTarget.user_id != userid || zoneSource.user_id != userid
				
			# Make sure there's enough soldiers to transfer.
			# ==============================================

			return :must_remain_one 		if count == zoneSource.soldiers
			return :not_enough_soldiers 	if count > zoneSource.soldiers

			# Do the transfer.
			# ================

			zoneSource.soldiers -= count
			zoneTarget.soldiers += count
			user.spend_turns( GameRules::COST_MOVE_SOLDIERS )

			begin
				User.transaction do
					user.save()
					zoneSource.save()
					zoneTarget.save()
				end
			rescue
				return :database_error
			end

			# Done!
			# =====

			return { :time => Time.now, :czones => [ zoneSource, zoneTarget ], :user => user }
			
		end

		## Return values:
		## @result		true
		##				:database_error
		##				:no_artillery_at_source
		##				:artillery_at_target
		##				:zones_not_owned
		##				:zones_not_adjacent
		def self.move_artillery( userid, targetX, targetY, sourceX, sourceY )

			# Make sure the zones are next to each other.
			# ===========================================

			#return :zones_not_adjacent if ( abs( targetX - sourceX ) == 1 ) ^ ( abs( targetY - sourceY ) == 1 )

			# Make sure there's enough turns to do this.
			# ==========================================

			user = User.find_by_id( userid )
			return :user_auth_error  if user.nil?
			return :not_enough_turns if user.peek_current_turn_count() < GameRules::COST_MOVE_ARTILLERY

			# Get the zones
			# =============

			zoneTarget	= Zone.get_zone_at( targetX, targetY )
			zoneSource	= Zone.get_zone_at( sourceX, sourceY )

			return :zones_not_owned if zoneTarget.nil? || zoneSource.nil?
			return :zones_not_owned if zoneTarget.user_id != userid || zoneSource.user_id != userid

			# Make sure the artillery can be transferred.
			# ===========================================

			return :no_artillery_at_source 	if zoneSource.artillery == false
			return :artillery_at_target 	if zoneTarget.artillery == true

			# Do the transfer.
			# ================

			zoneSource.artillery = false
			zoneTarget.artillery = true
			user.spend_turns( GameRules::COST_MOVE_ARTILLERY )

			begin
				User.transaction do
					user.save()
					zoneSource.save()
					zoneTarget.save()
				end
			rescue
				return :database_error
			end

			# Done!
			# =====

			return { :time => Time.now, :czones => [ zoneSource, zoneTarget ], :user => user }
			
		end

		## @result		true
		##				:user_auth_error
		##				:database_error
		##				:invalid_parameters
		##				:zone_not_owned
		##				:already_artillery
		##				:insufficient_turns
		def self.build_artillery( userid, targetX, targetY )

			# Make sure the user has enough turns
			# ===================================

			user = User.find_by_id( userid )
			return :user_auth_error		if user.nil?
			return :insufficient_turns	if user.peek_current_turn_count() < GameRules::COST_ARTILLERY

			# Make sure the zone is owned by the player.
			# ==========================================

			targetZone = Zone.get_zone_at( targetX, targetY )
			return :zone_not_owned		if targetZone.nil?
			return :zone_not_owned		if targetZone.user_id != userid
			return :already_artillery	if targetZone.artillery == true

			# Do it!
			# ======

			targetZone.artillery = true
			user.spend_turns( GameRules::COST_ARTILLERY )

			begin
				User.transaction do
					user.save()
					targetZone.save()
				end
			rescue
				return :database_error
			end

			# Done!
			# =====

			return { :time => Time.now, :czones => [ targetZone ], :user => user }

		end

		## @result		true
		##				:user_auth_error
		##				:database_error
		##				:invalid_parameters
		##				:zone_not_owned
		##				:already_bunker
		##				:insufficient_turns
		def self.build_bunker( userid, targetX, targetY )

			# Make sure the user has enough turns
			# ===================================

			user = User.find_by_id( userid )
			return :user_auth_error		if user.nil?
			return :insufficient_turns	if user.peek_current_turn_count() < GameRules::COST_BUNKER

			# Make sure the zone is owned by the player.
			# ==========================================

			targetZone = Zone.get_zone_at( targetX, targetY )
			return :zone_not_owned		if targetZone.nil?
			return :zone_not_owned		if targetZone.user_id != userid
			return :already_bunker		if targetZone.bunker == true

			# Do it!
			# ======

			targetZone.bunker = true
			user.spend_turns( GameRules::COST_BUNKER )

			begin
				User.transaction do
					user.save()
					targetZone.save() 
				end
			rescue
				return :database_error
			end

			# Done!
			# =====

			return { :time => Time.now, :czones => [ targetZone ], :user => user }

		end

		##		:user_auth_error
		##		:invalid_target
		##		:cant_attack_zone
		def self.get_attack_cost( userid, targetX, targetY )

			# Get the targeted zones and attacking zones.
			# ===========================================

			dzone = Zone.get_zone_at( targetX, targetY )
			return :invalid_target if dzone == nil
			return :invalid_target if dzone.user_id == userid

			#dzones = Zone.get_zones_by_user_in_area( dzone.user_id, targetX-1, targetX+1, targetY-1, targetY+1 )
			azones = Zone.get_zones_by_user_in_area( userid, targetX-1, targetX+1, targetY-1, targetY+1 )

			# Total the amount of attacking and defending soldiers
			# ====================================================

			dsoldiercount	= dzone.soldiers
			asoldiercount	= 0
			for z in azones
				asoldiercount += z.soldiers if z.x == targetX || z.y == targetY
			end

			return GameRules::game_zone_attack_cost( asoldiercount, dsoldiercount )

		end

	    ## @result		true
		##				:user_auth_error
		##				:database_error
		##				:zone_not_owned
		##				:already_jtower
		##				:insufficient_turns
		def self.build_jamming_tower( userid, targetX, targetY )

			# Make sure the user has enough turns
			# ===================================

			user = User.find_by_id( userid )
			return :user_auth_error		if user.nil?
			return :insufficient_turns	if user.peek_current_turn_count() < GameRules::COST_JAMMING_TOWER

			# Make sure the zone is owned by the player.
			# ==========================================

			targetZone = Zone.get_zone_at( targetX, targetY )
			return :zone_not_owned		if targetZone.nil?
			return :zone_not_owned		if targetZone.user_id != userid
			return :already_jtower		if targetZone.jamming == true

			# Do it!
			# ======

			targetZone.jamming = true
			user.jammingcount += 1
			user.spend_turns( GameRules::COST_JAMMING_TOWER )

			begin
				User.transaction do
					user.save()
					targetZone.save()
				end
			rescue
				return :database_error
			end

			# Done!
			# =====

			return { :time => Time.now, :czones => [ targetZone ], :user => user }

		end

	    ## @result		hash with :zones, :users
		def self.get_zone_data( minX, maxX, minY, maxY )

			# Grab the zones
			# ==============

			zones = Zone.find_zones_in_view_xml( minX, maxX, minY, maxY )

			# For each zone, go through and get users.
			# ========================================

			users = {}
			for z in zones
				if users[z.user_id] == nil
					users[z.user_id] = User.find_by_id( z.user_id )
				end
			end

			# Return the result!
			# ==================

			return { :zones => zones, :users => users }

        end
end
