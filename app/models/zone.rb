require 'gamerules'

class Zone < ActiveRecord::Base

  # Validation Stuff
  # ================

  validates_presence_of        :x
  validates_presence_of        :y
  validates_presence_of        :user_id
  validates_numericality_of    :x,            :only_integer => true,     :greater_than_or_equal_to => 0
  validates_numericality_of    :y,            :only_integer => true,     :greater_than_or_equal_to => 0
  validates_numericality_of    :user_id,    :only_integer => true,     :greater_than_or_equal_to => 0
  validates_numericality_of    :soldiers,    :only_integer => true,     :greater_than_or_equal_to => 1,    :allow_nil => true
  validate                    :unique_position

  # Functions
  # =========

  public

  ## Dave: Return zone from coordinate
  def self.get_zone_from_coordinates(x, y)
    @zone = find(:first, :conditions => "x = '#{x}' AND y = '#{y}'")
  end

  ## Returns an array of the zones without any pointless 2D grid stuff.
  def self.find_zones_in_view_xml( x_min, x_max, y_min, y_max )
    # find zones
    @zones = find(:all, :conditions => "x >= '#{x_min}' AND x <= '#{x_max}' AND y >= '#{y_min}' AND y <= '#{y_max}'")
  end

  #------------------------ alex get map data for user
  def self.find_zones_in_view(x_min, x_max, y_min, y_max)

    logger.info "XIN_DEBUG: x:#{x_min}, x:#{x_max}, y:#{y_min}, ymax:#{y_max}"
    # for invalid input, return nil
    if (x_min > x_max or y_min > y_max)
      nil
    else
      #returns a 2D array of the zones in the current view

      # 2D grid - init
      grid = Array.new(x_max-x_min + 1) { Array.new(y_max-y_min + 1) }
      # find zones
      zones = find(:all, :conditions => "x >= '#{x_min}' AND x <= '#{x_max}' AND y >= '#{y_min}' AND y <= '#{y_max}'")

      # assign zones to grid
      for zone in zones
        grid[zone.x - x_min][zone.y - y_min] = zone
      end

      grid
    end
  end

  #-------------------------Xin
  def self.find_users_in_area(zones)
    # return a owners list of the zones lists
    users_in_area = Array.new(0, User.new)
    for i in (0..zones.size - 1)
      for j in (0..zones[i].size - 1)
        if (zones[i][j] and zones[i][j].user_id >= 0)
          if (users_in_area.length == 0 or not users_in_area.find{|user| user.id == zones[i][j].user_id})  # the current user has not been added
            new_user = User.find_by_id(zones[i][j].user_id)
            users_in_area.push(new_user)
          end
        end
      end
    end
    users_in_area
  end

  #-----------------------------------------Shane
  ## Returns zone at position.
  def self.get_zone_at( x, y )
    find( :first, :conditions => { :x => x, :y => y } )
  end

  #-----------------------------------------Shane
  ## Returns all zones for a given user.
  def self.get_zones_by_user( user_id )
    find( :all, :conditions => { :user_id => user_id } )
  end

  #-----------------------------------------Shane
  def self.get_zones_by_user_in_area( user_id, max_x, min_x, max_y, min_y )
    find( :all, :conditions => "user_id == '#{user_id}' AND x >= '#{x_min}' AND x <= '#{x_max}' AND y >= '#{y_min}' AND y <= '#{y_max}'" )
  end

  #-----------------------------------------Shane
  ## Returns total # of zones for a given user.
  def self.get_total_zones_for_user( user_id )
    return get_zones_by_user( user_id ).size()
  end

  ## Function that returns zones expandable by the given user in a certain grid... and put it into the given
  ## given grid object? Uh... whatever. Seems pretty deprecated to me.
  def self.remark_expandable_zones(x_min, x_max, y_min, y_max, grid, user_id)

    if not grid
      return
    end
    # find all the zones belonging to a certain user specified by user_id
    zones = find(:all, :conditions => "x >= '#{x_min}' AND x <= '#{x_max}' AND \
                                                        y >= '#{y_min}' AND y <= '#{y_max}' AND user_id = '#{user_id}'")

    # find the all the neighbor zones and check if it is already expanded, if not add it to the grid
    for zone in zones
      for oset in GameRules::ZONE_EXPANDABLE_AREA_OFFSETS
        xnew = zone.x + oset[0] - x_min
        ynew = zone.y + oset[1] - y_min
        if xnew >= grid.size() or ynew >= grid[xnew].size() or not grid[xnew]
          break
        end
        if not grid[xnew][ynew]
          grid[xnew][ynew] = Zone.new
          grid[xnew][ynew].x = zone.x + oset[0]
          grid[xnew][ynew].y = zone.y + oset[1]
          grid[xnew][ynew].user_id = -1
        end
      end
    end
  end

  ## Returns the zones that the user can expand into. Doesn't do any culling by ocean.
  ## Returns an array with objects with values :x and :y. So obj(:x) and obj(:y) will give you the position of them.
  def self.get_expandable_zones( user_id )

    # Get the size of the user's territory and make a 2D array of it that extends one zone on either side
    # of the user's territory.
    # ---------------------------------------------------------------------------------------------------

    bounds     = get_zone_area( user_id )
    width     = bounds(:max_x) - bounds(:min_x)
    height     = bounds(:max_y) - bounds(:min_y)
    grid     = Array.new(width+3) { Array.new(height+3) }    # +3 because you need to add 1 to get the # of zones along an axis
    # and then another 2 to put padding around the area to grow/expand.

    # For each zone owned by the user, mark all spots on the grid that can expanded into.
    # Make note to offset based on relative position of the grid's origin to the world map.
    # Note wrap-around on the world map, except along the Y-axis.
    #
    # Basically what I'll do is... if there's boundary conditions in play across this zone,
    # I'll translate each point to be relative to the grid space. Later I'll retranslate
    # these points into X/Y points on the actual world map.
    # -------------------------------------------------------------------------------------

    base_x    = bounds(:min_x)-1        # -1 because I'm making one zone of room around the user's territory.
    base_y    = bounds(:min_y)-1
    uzones    = get_zones_by_user( user_id )

    for z in uzones
      for o in GameRules::ZONE_EXPANDABLE_AREA_OFFSETS
        grid[ z.x + o(0) - base_x ][ z.y + o(1) - base_y ] = true
      end
    end

    # Get all zones in the bounding box of the expandable zone set and remove any zones
    # from the set of expandable zones that are owned by any player.
    # ---------------------------------------------------------------------------------

    pzones    = find_zones_in_view_xml( bounds(:min_x)-1, bounds(:max_x)+1, bounds(:min_y)-1, bounds(:max_y)+1 )

    for z in pzones
      grid[ z.x + o(0) - base_x ][ z.y + o(1) - base_y ] = nil
    end

    # Take the 2D array and make it a list.
    # -------------------------------------

    zlist = []
    0.upto(width+3) do |i|
      0.upto(height+3) do |j|
        zlist << { :x => base_x+i, :y => base_y+j } if grid[i][j] == true    # << appends to an array.
      end
    end

    # Return the list
    # ---------------

    return zlist

  end

  ## Returns a hash with :max_x, :max_y, :min_y, :min_x
  def self.get_zone_area( user_id )
    maxx = maximum( :x, :conditions => { :user_id => user_id } )
    return { :max_x => 0, :max_y => 0, :min_x => 0, :min_y => 0 } if maxx.nil?

    maxy = maximum( :y, :conditions => { :user_id => user_id } )
    minx = minimum( :x, :conditions => { :user_id => user_id } )
    miny = minimum( :y, :conditions => { :user_id => user_id } )

    return { :max_x => maxx, :max_y => maxy, :min_x => minx, :min_y => miny }
  end

  def self.get_zone_size( user_id )
    bounds = get_zone_area( user_id )
    return { :width =>     bounds(:max_x) - bounds(:min_x),
        :height =>    bounds(:max_y) - bounds(:min_y) }
  end

  private

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
