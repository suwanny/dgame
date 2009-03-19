require 'memcache_util.rb'

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
=begin
        if GameController::USE_MEMCACHED 
            if MEMCACHED_AreAllZonesInMemory(x_min, x_max, y_min, y_max)
                # read all the zones from the cache
                return MEMCACHED_GetZonesFromMemory(x_min, x_max, y_min, y_max)
            end
            zones = find(:all, :conditions => "x >= '#{x_min}' AND x <= '#{x_max}' AND y >= '#{y_min}' AND y <= '#{y_max}'")
            MEMCACHED_PutZonesToMemory(x_min, x_max, y_min, y_max, zones)
            return zones
        else
=end
            return find(:all, :conditions => "x >= '#{x_min}' AND x <= '#{x_max}' AND y >= '#{y_min}' AND y <= '#{y_max}'")
=begin
        end
=end
	end

	def self.get_total_zone_count
		return self.count
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
        return count( :select => "user_id", :conditions => { :user_id => user_id } )
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
            if grid[ z.x - base_x ] and grid[z.x - base_x][ z.y - base_y ]
                grid[ z.x - base_x ][ z.y - base_y ] = true
            end   
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

    # serialization of the object
    def from_json(json)
        self.attributes = ActiveSupport::JSON.decode(json)
        self
    end

    def to_json(options = {})
        JsonSerializer.new(self, options).to_s
    end

    def to_zoneXML()
        return "<zone bunker=\"#{bunker}\" jamming=\"#{jamming}\" x=\"#{x}\" y=\"#{y}\" id=\"#{id}\" soldiers=\"#{soldiers}\" artillery=\"#{artillery}\"/>"
    end


    # for the view to use
    def self.GetBackgroundGridHTMLStr(x1, x2, y1, y2, user, grid_w)
        if GameController::USE_MEMCACHED
            str = MEMCACHED_GetBackgroundGridHTMLStr(x1, x2, y1, y2, user, grid_w)
            if str != nil
                return str
            end
        end
        tablew = (x2 - x1 + 1) * (grid_w + 1) + 1
        s = "";
        s += "<table cellpadding=0 cellspacing=0 border=0 width=#{tablew}>\n"
        s += "<tr height=1 class=\"cell_lightest\">\n"
        xspan = (x2 - x1 + 1) * 2 + 1
        s += "<td colspan=#{xspan}><\/td>\n"
        s += "<\/tr>\n"
        for y in (y1..y2)
            s += "<tr height=#{grid_w}>\n"
            s += "<td width=1 class=\"cell_lightest\"><\/td>\n"
            for x in (x1..x2)
                s += "<td width=#{grid_w}>"
                if user and user.total_zones == 0 #user has no zone
                    s += "<a href=\"/game/expand_into_zone?targetX=#{x}&targetY=#{y}\">"
                    s += "<img border=0 alt=\"\" src=\"/images/spacer.gif\" width=#{grid_w} height=#{grid_w}>"
                    s += "</a>\n"
                end
                s += "<\/td>\n"
                s += "<td width=1 class=\"cell_lightest\"><\/td>\n"
            end #for x
            s += "<\/tr>\n"
            s += "<tr height=1 class=\"cell_lightest\">"
            s += "<td colspan=#{xspan}><\/td>"
            s += "<\/tr>\n"
        end #for y
        s += "<\/table>\n"
        if GameController::USE_MEMCACHED
            MEMCACHED_PutBackgroundGridHTMLStr(s, x1, x2, y1, y2, user, grid_w)
        end
        return s
    end

    private

    ## Validation method. Should enforce that a zone is the only zone for this location.
    ## The loop is there because when you update a zone's fields and save it, this gets checked again.
    ## So you need to check if there it's the only one in there for that location, or not at all if
    ## it's not put in there yet.

    def unique_position
        zHere = Zone.find( :first, :select => "id", :conditions => ["x = ? AND y = ? AND id != ?", x, y, id])
                #:conditions => { :x => x, :y => y, :id !=> id } )

        #errors.add( :x, 'Duplicate zone at position.' ) if zHere.size > 0
        #errors.add( :y, 'Duplicate zone at position.' ) if zHere.size > 0

        if zHere and zHere.size() > 0 and zHere[0] then
            errors.add( zHere[0].id, 'Duplicate zone at id.' )
        end
    end

    def self.getNeighborGrid(x_min, x_max, y_min, y_max, zones)
        # do the optimization of adjacent zone effect here
        user_grids = Array.new(y_max - y_min + 1) { Array.new(x_max - x_min + 1) }
        aux_grids = Array.new(y_max - y_min + 1) { Array.new(x_max - x_min + 1) }
        for z in zones
            x = z.x - x_min
            y = z.y - y_min
            user_grids[y][x] = z.user_id
        end
        for z in zones
            x = z.x - x_min
            y = z.y - y_min
            if y > 0
                if z.user_id == user_grids[y - 1][x]
                    if aux_grids[y - 1] and aux_grids[y - 1][x]
                        aux_grids[y - 1][x] += 2   #top position
                    else
                        aux_grids[y - 1][x] = 2   #top position
                    end
                end
            end
            if x > 0
                if z.user_id == user_grids[y][x - 1]
                    if aux_grids[y] and aux_grids[y][x - 1]
                        aux_grids[y][x - 1] += 4   #top position
                    else
                        aux_grids[y][x - 1] = 4   #top position
                    end
                end
            end
        end
        return aux_grids
    end
        # the optimization of adjacent zone effect ends here

    private
    # the memcached functions that would only be used by this model

        ## memcached functions: return whether all the zones are already in the memory
        def self.MEMCACHED_AreAllZonesInMemory(xmin, xmax, ymin, ymax)
            return :wrong_parameter if xmin == nil or xmax == nil or ymin == nil or ymax == nil
            logger.info("MEMCACHED_AreAllZonesInMemory(#{xmin},#{xmax},#{ymin},#{ymax})")            
            x1 = Cache.get("Effective_view_xmin")
            x2 = Cache.get("Effective_view_xmax")
            y1 = Cache.get("Effective_view_ymin")
            y2 = Cache.get("Effective_view_ymax")
            logger.info("MEMCACHED_AreAllZonesInMemory(#{x1},#{x2},#{y1},#{y2})")
            return false if x1 == nil or x2 == nil or y1 == nil or y2 == nil
            return false if x1 > xmin or x2 < xmax or y1 > ymin or y2 < ymax
            return true #the whole region is already included
        end

        ## memcached functions: return all the zones within a certain view port in the cache
        def self.MEMCACHED_GetZonesFromMemory(xmin, xmax, ymin, ymax)
            logger.info("MEMCACHED_GetZonesFromMemory(#{xmin},#{xmax},#{ymin},#{ymax})")
            return :wrong_parameter if xmin == nil or xmax == nil or ymin == nil or ymax == nil
            zones = []
=begin
            for x in (xmin..xmax)
                for y in (ymin..ymax)
                    str = Cache.get("Zone_" + x.to_s + "_" + y.to_s)
                    if !str        # the zone at a certain position doesn't exist
                        next
                    end
                    z = Zone.new
                    z.from_json(str)
                    z.id=2
                    logger.info("AAA#{str} z.id:#{z.id}")
                    if z
                        zones << z
                    end
                end
            end
=end
            s = Cache.get("aaa")
            logger.info("s:#{s}")
            return zones
        end

        ## memcached functions: combine two views (if applicable)
        def self.MEMCACHED_UpdateEffectiveView(xmin, xmax, ymin, ymax)
            logger.info("MEMCACHED_UpdateEffectiveView(#{xmin},#{xmax},#{ymin},#{ymax})")
            shouldUpdate = false
            x1 = Cache.get("Effective_view_xmin")
            x2 = Cache.get("Effective_view_xmax")
            y1 = Cache.get("Effective_view_ymin")
            y2 = Cache.get("Effective_view_ymax")
            if x1 == nil or x2 == nil or y1 == nil or y2 == nil or (x2 - x1) * (y2 - y1) > 10000
                shouldUpdate = true
            else
                if x1 == xmin and x2 == xmax and y1 == ymin and y2 == ymax
                    return  # the same view
                end
                if x1 == xmin and x2 == xmax
                    if (ymin <= y1 and ymax >= y1) or (y1 <= ymin and y2 >= ymin)
                        ymin = [y1, ymin].min
                        ymax = [y2, ymax].max
                        Cache.put("Effective_view_ymin", ymin)
                        Cache.put("Effective_view_ymax", ymax)
                    end #perfectly overlaps
                else
                    if y1 == ymin and y2 == ymax
                        if (xmin <= x1 and xmax >= x1) or (x1 <= xmin and x2 >= xmin)
                            xmin = [x1, xmin].min
                            xmax = [x2, xmax].max
                            Cache.put("Effective_view_xmin", xmin)
                            Cache.put("Effective_view_xmax", xmax)
                        end #perfectly overlaps
                    else
                        shouldUpdate =true
                    end
                end
            end
            if shouldUpdate
                Cache.put("Effective_view_xmin", xmin)
                Cache.put("Effective_view_xmax", xmax)
                Cache.put("Effective_view_ymin", ymin)
                Cache.put("Effective_view_ymax", ymax)
            end
        end


        ## memcached functions: store all the zones within a certain view port to the cache
        def self.MEMCACHED_PutZonesToMemory(xmin, xmax, ymin, ymax, zones)
            logger.info("MEMCACHED_PutZonesToMemory(#{xmin},#{xmax},#{ymin},#{ymax})")
            return :wrong_parameter if xmin == nil or xmax == nil or ymin == nil or ymax == nil

            if MEMCACHED_AreAllZonesInMemory(xmin, xmax, ymin, ymax)
                #if the current view is already contained in the memory,
                # do not update the boundary of view in the cache
            else
                # combine the existing view with the current view (if applicable)
                MEMCACHED_UpdateEffectiveView(xmin, xmax, ymin, ymax)
            end

            s = ""
            for z in zones
                s += z.to_json
            end
            Cache.put("aaa", s)
            #for z in zones
            #    Cache.put("Zone_" + z.x.to_s + "_" + z.y.to_s, z.to_json)
            #end
        end

        ##memcached function store the XML format for a set of zones
        def self.MEMCACHED_SaveZoneXML(xmin, xmax, ymin, ymax, zones)
            logger.info("MEMCACHED_SaveZoneXML(#{xmin},#{xmax},#{ymin},#{ymax})")
            return :wrong_parameter if xmin == nil or xmax == nil or ymin == nil or ymax == nil

            Cache.put("Effective_view_xmin", xmin)
            Cache.put("Effective_view_xmax", xmax)
            Cache.put("Effective_view_ymin", ymin)
            Cache.put("Effective_view_ymax", ymax)

            s = ""
            for z in zones
                s += z.to_zoneXML + "\n\r"
            end
            Cache.put("Zones_XML", s)
            logger.info("Zones_XML:"+s)

            return s
            #for z in zones
            #    Cache.put("Zone_" + z.x.to_s + "_" + z.y.to_s, z.to_json)
            #end

        end

        ##memcached function load the XML format for a set of zones
        def self.MEMCACHED_LoadZoneXML
            return Cache.get("Zones_XML")
        end

        ##memcached function load the XML format for a set of zones
        def self.MEMCACHED_ViewportSame(xmin, xmax, ymin, ymax)
            return false if xmin == nil or xmax == nil or ymin == nil or ymax == nil

            x1 = Cache.get("Effective_view_xmin")
            x2 = Cache.get("Effective_view_xmax")
            y1 = Cache.get("Effective_view_ymin")
            y2 = Cache.get("Effective_view_ymax")
            return false if x1 != xmin or x2 != xmax or y1 != ymin or y2 != ymax
            return true
        end

        def self.MEMCACHED_GetBackgroundGridHTMLStr(xmin, xmax, ymin, ymax, user, grid_w)
            if user and user.total_zones == 0
                bgGridHTMLName = "Background_Grid_#{xmin}_#{xmax}_#{ymin}_#{ymax}_#{grid_w}_n"
            else
                bgGridHTMLName = "Background_Grid_0_#{xmax-xmin}_0_#{ymax-ymin}_#{grid_w}_y"
            end
            str = Cache.get(bgGridHTMLName)
            if str
                logger.info("MEMCACHED_GetBackgroundGridHTMLStr(#{bgGridHTMLName}) str=#{str.length}")
            end
            return str
        end

        def self.MEMCACHED_PutBackgroundGridHTMLStr(str, xmin, xmax, ymin, ymax, user, grid_w)

            if user and user.total_zones == 0
                bgGridHTMLName = "Background_Grid_#{xmin}_#{xmax}_#{ymin}_#{ymax}_#{grid_w}_n"
            else
                bgGridHTMLName = "Background_Grid_0_#{xmax-xmin}_0_#{ymax-ymin}_#{grid_w}_y"
            end
            logger.info("MEMCACHED_PutBackgroundGridHTMLStr(#{bgGridHTMLName}), str = #{str.length}")
            Cache.put(bgGridHTMLName, str, 60)
        end
    # end of the memcached functions that would only be used by this model
end
