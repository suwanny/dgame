class Zone < ActiveRecord::Base

	belongs_to						:user

    # Validation Stuff
    # ================

    validates_presence_of           :x
    validates_presence_of           :y
    validates_presence_of           :user_id
	validates_presence_of			:score
    validates_numericality_of       :x,					:only_integer => true,     :greater_than_or_equal_to => 0
    validates_numericality_of       :y,					:only_integer => true,     :greater_than_or_equal_to => 0
    validates_numericality_of  		:user_id,			:only_integer => true,     :greater_than_or_equal_to => 0
	validates_numericality_of       :soldiers,			:only_integer => true,     :greater_than_or_equal_to => 1,    :allow_nil => true
	validates_numericality_of       :score,				:only_integer => true,     :greater_than_or_equal_to => 0
    validate                        :unique_position

    # Functions
    # =========

    public
    
    ## Returns zone at position.
    def self.get_zone_at( x, y )
        return find( :first, :conditions => { :x => x, :y => y } )
    end

    ## Returns an array of the zones owned by a given user.
    ## If the range is invalid, return nil
    def self.find_zones_in_view_xml( x_min, x_max, y_min, y_max )
        if x_max < x_min or y_max < y_min or x_max < 0 or y_max < 0
            return nil
        end
        return find(:all, :conditions => "x >= '#{x_min}' AND x <= '#{x_max}' AND y >= '#{y_min}' AND y <= '#{y_max}'")
    end

    ## Returns all zones for a given user.
    def self.get_zones_by_user( user_id )
        return find( :all, :conditions => { :user_id => user_id } )
    end

    ## Returns all zones for a given user within given bounds.
    def self.get_zones_by_user_in_area( user_id, x_min, x_max, y_min, y_max )
        return find( :all,
                :conditions => "user_id = '#{user_id}' AND x >= '#{x_min}' AND x <= '#{x_max}' AND y >= '#{y_min}' AND y <= '#{y_max}'" )
    end

    ## Returns all zones for a given user within given bounds.
    def self.get_zones_in_area_not_owned_by_user( user_id, x_min, x_max, y_min, y_max )
        return find( :all, :conditions => "user_id != '#{user_id}' AND x >= '#{x_min}' AND x <= '#{x_max}' AND y >= '#{y_min}' AND y <= '#{y_max}'" )
    end

    ## Returns total # of zones for a given user.
    def self.get_total_zones_for_user( user_id )
        return count( :all, :conditions => { :user_id => user_id } )
    end

    ## Returns an array of zones in a certain area that the user can attack. Doesn't take into account cost to attack. Doesn't count zones that artillery only can hit.
    def self.get_attackable_zones_in_view( user_id, x_min, x_max, y_min, y_max )
        user = User.find_by_id( user_id )
        if user.nil?
            return :user_not_found
        end
        width         = x_max - x_min
        height         = y_max - y_min
        grid         = Array.new(width+3) { Array.new(height+3) }    # +3 because you need to add 1 to get the # of zones along an axis
        # and then another 2 to put padding around the area to grow/expand.
        # Mark each spot on the grid that the user has.
        # ---------------------------------------------
        base_x        = x_min-1                               # -1 because I'm making one zone of room around the user's territory.
        base_y        = y_min-1

        uzones = get_zones_by_user( user_id )
        for z in uzones
            grid[ z.x - base_x ][ z.y - base_y ] = true
        end

        # Get all zones in the area not owned by the given user. If any such zone is adjacent
        # to a user owned zone, then throw it into a list of attackable zones.
        # -----------------------------------------------------------------------------------

        ezones         = get_zones_in_area_not_owned_by_user( user_id, x_min-1, x_max+1, y_min-1, y_max+1 )
        attackable     = []

        for z in ezones
            for o in GameRules::ZONE_EXPANDABLE_AREA_OFFSETS
                x = ( z.x + o[0] - base_x )                            # These are the X and Y I'm checking to see if is owned by the player.
                y = ( z.y + o[1] - base_y )
                if x >= 0 && x < width+3 && y >= 0 && y < height+3
                    if grid[x][y] == true
                        attackable << z
                    end
                end
            end
        end

        # Return the list of attackable zones!
        # ------------------------------------

        return attackable
    end

    ## Returns an array of zones that the user can attack. Doesn't take into account cost to attack. Doesn't count zones that artillery only can hit.
    def self.get_attackable_zones( user_id )

        bounds        = get_zone_area( user_id )
        return get_attackable_zones_in_view( user_id, bounds[:min_x]-1, bounds[:max_x]+1, bounds[:min_y]-1, bounds[:max_y]+1 )

    end

    ## Return the expandable zones in a certain area for the user
    def self.get_expandable_zones_in_view(user_id, x_min, x_max, y_min, y_max)
        width         = x_max - x_min
        height         = y_max - y_min
        grid         = Array.new(width+3) { Array.new(height+3) }    # +3 because you need to add 1 to get the # of zones along an axis
        # and then another 2 to put padding around the area to grow/expand.

        # For each zone owned by the user, mark all spots on the grid that can expanded into.
        # Make note to offset based on relative position of the grid's origin to the world map.
        # Note wrap-around on the world map, except along the Y-axis.
        #
        # Basically what I'll do is... if there's boundary conditions in play across this zone,
        # I'll translate each point to be relative to the grid space. Later I'll retranslate
        # these points into X/Y points on the actual world map.
        # -------------------------------------------------------------------------------------

        base_x        = x_min - 1                               # -1 because I'm making one zone of room around the user's territory.
        base_y        = y_min - 1
        uzones        = get_zones_by_user_in_area( user_id, x_min, x_max, y_min, y_max )

        for z in uzones
            for o in GameRules::ZONE_EXPANDABLE_AREA_OFFSETS
                grid[ z.x + o[0] - base_x ][ z.y + o[1] - base_y ] = true
            end
        end

        # Get all zones in the bounding box of the expandable zone set and remove any zones
        # from the set of expandable zones that are owned by any player.
        # ---------------------------------------------------------------------------------

        pzones    = find_zones_in_view_xml( x_min - 1, x_max + 1, y_min - 1, y_max + 1 )

        for z in pzones
            grid[ z.x - base_x ][ z.y - base_y ] = nil
        end

        # Take the 2D array and make it a list.
        # -------------------------------------

        zlist = []
        0.upto(width+3) do |i|
            0.upto(height+3) do |j|
                zlist << { :x => base_x+i, :y => base_y+j } if grid[i] and grid[i][j] == true    # << appends to an array.
            end
        end

        # Return the list
        # ---------------

        return zlist
    end

    ## Returns the zones that the user can expand into. Doesn't do any culling by ocean. Yet.
    ## Returns an array with objects with values :x and :y. So obj[:x] and obj[:y] will give you the position of them, in terms of integer zone coordinates.
    def self.get_expandable_zones( user_id )

        # Get the size of the user's territory and make a 2D array of it that extends one zone on either side
        # of the user's territory.
        # ---------------------------------------------------------------------------------------------------
        bounds        = get_zone_area( user_id )
        return get_expandable_zones_in_view(user_id, bounds[:min_x], bounds[:max_x], bounds[:min_y], bounds[:max_y])
    end

    ## Returns the bounds of the given user's territory by integer zone coordinates.
    ## Returns a hash with :max_x, :max_y, :min_y, :min_x
    def self.get_zone_area( user_id )
        maxx = maximum( :x, :conditions => { :user_id => user_id } )
        return { :max_x => 0, :max_y => 0, :min_x => 0, :min_y => 0 } if maxx.nil?

        maxy = maximum( :y, :conditions => { :user_id => user_id } )
        minx = minimum( :x, :conditions => { :user_id => user_id } )
        miny = minimum( :y, :conditions => { :user_id => user_id } )

        return { :max_x => maxx, :max_y => maxy, :min_x => minx, :min_y => miny }
    end

    ## Returns the size of the given user's territory by integer width and height.
    ## Returns a hash with :width and :height.
    def self.get_zone_size( user_id )
        bounds = get_zone_area( user_id )
        return { :width => bounds[:max_x] - bounds[:min_x],    :height => bounds[:max_y] - bounds[:min_y] }
    end

    #-------------------------Xin
    def self.find_users_in_area(zones)
        if zones == nil
            return nil
        end
        # return a owners list of the zones lists
        users_in_area = Array.new(0, User.new)
        for zone in zones
            if (users_in_area.length == 0 or not users_in_area.detect {|user| user.id == zone.user_id})  # the current user has not been added
                new_user = User.find_by_id(zone.user_id)
                users_in_area.push(new_user)
            end
        end
        return users_in_area
    end

    private

    ## Validation method. Should enforce that a zone is the only zone for this location.
    ## The loop is there because when you update a zone's fields and save it, this gets checked again.
    ## So you need to check if there it's the only one in there for that location, or not at all if
    ## it's not put in there yet.

    def unique_position
        zHere = Zone.find( :all, :conditions => { :x => x, :y => y } )

        #errors.add( :x, 'Duplicate zone at position.' ) if zHere.size > 0
        #errors.add( :y, 'Duplicate zone at position.' ) if zHere.size > 0

        for z in zHere
            if z.id != id then
                errors.add( :x, 'Duplicate zone at position.' )
                errors.add( :y, 'Duplicate zone at position.' )
            end
        end
    end
end
