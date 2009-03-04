require 'test_helper'

class ZoneTest < ActiveSupport::TestCase

    fixtures :zones

    test "the truth" do
        assert true
    end

    test "populate gameboard for user" do

    end

    test "get total zones for user" do
        #the zone number of a non-existent user is 0
        assert_equal Zone.get_total_zones_for_user(-1), 0

        zone_dave_a = zones(:zone_dave_a)
        assert_equal Zone.get_total_zones_for_user(zone_dave_a.user_id),
                Zone.find( :all, :conditions => { :user_id => zone_dave_a.user_id } ).size()

        zone_dave_a.delete

        assert_equal Zone.get_total_zones_for_user(zone_dave_a.user_id),
                Zone.find( :all, :conditions => { :user_id => zone_dave_a.user_id } ).size()

    end

    test "get total zones for user when zone changes owner" do
        #the zone number of a non-existent user is 0
        zone_dave_a 			= zones(:zone_dave_a)
        david_id 				= zone_dave_a.user_id
        old_david_zone_number 	= Zone.get_total_zones_for_user(david_id)
        bob_id 					= users(:bob).id
        old_bob_zone_number 	= Zone.get_total_zones_for_user(bob_id)
        zone_dave_a.user_id 	= bob_id
        assert (zone_dave_a.save)

        assert_equal Zone.get_total_zones_for_user(david_id), old_david_zone_number - 1
        assert_equal Zone.get_total_zones_for_user(bob_id), old_bob_zone_number + 1

    end

    test "find zones in view" do
        zones = Zone.find_zones_in_view_xml(0, 20, 0, 20)
        zone_dave_a = zones(:zone_dave_a)

        # assert the zones that are occupied are set in the array
        assert_not_nil zones.detect {|zone| zone.x == 15 and zone.y == 15}
        assert_not_nil zones.detect {|zone| zone.x == zone_dave_a.x and zone.y == zone_dave_a.y}

        # assert the zones that are not occupied is not set value
        assert_nil zones.detect {|zone| zone.x == 4 and zone.y == 4}

        # assert the invalid parameter will give the nil return
        assert_nil Zone.find_zones_in_view_xml(3, 0, 0, -1)
        assert_nil Zone.find_zones_in_view_xml(0, 3, 0, -1)
        assert_nil Zone.find_zones_in_view_xml(0, -3, 0, -1)

    end

    test "get expandable zones" do
        zone_15_15 = zones(:zone_15_15)
        zones = Zone.get_expandable_zones(zone_15_15.user_id)

        # make sure the expandable zones are included
        for o in GameRules::ZONE_EXPANDABLE_AREA_OFFSETS
            assert_not_nil zones.detect {|zone| zone[:x] == zone_15_15.x + o[0] and zone[:y] == zone_15_15.y + o[1]}
        end
        # make sure the original zone is not included
        assert_nil zones.detect {|zone| zone[:x] == zone_15_15.x and zone[:y] == zone_15_15.y}
    end

    test "get expandable zones in view with obstacles" do
        zone_15_15 				= zones(:zone_15_15)
        zone_15_16 				= Zone.new
        zone_15_16.x 			= 15
        zone_15_16.y 			= 16
        zone_15_16.user_id 		= 1
        zone_15_16.soldiers 	= 1
		zone_15_16.score 		= 5

		user 					= User.find_by_id( zone_15_16.user_id )
		user.score 				+= zone_15_16.score
		user.total_soldiers		+= zone_15_16.soldiers
		user.total_zones		+= 1

		User.transaction do
        	assert zone_15_16.save
			assert user.save
		end
        zones = Zone.get_expandable_zones_in_view(zone_15_15.user_id, 10, 20, 10, 20)

        # make sure the obstacle is not included
        assert_nil zones.detect {|zone| zone[:x] == zone_15_16.x and zone[:y] == zone_15_16.y}

        # make sure the out-of-boundary zones are not included
        assert_nil zones.detect {|zone| zone[:x] > 21 or zone[:y] > 21 or zone[:x] < 9 or zone[:y] < 9}

        zones = Zone.get_expandable_zones_in_view(zone_15_15.user_id, 15, 20, 15, 20)
        # make sure the out-of-boundary zones are not included
        assert_nil zones.detect {|zone| zone[:x] > 21 or zone[:y] > 21 or zone[:x] < 14 or zone[:y] < 14}

    end

	test "empty zone is not valid." do
        z = Zone.new
		assert( !z.save() )
	end

	test "zones can't be put into the same position." do
		z = Zone.new( :x => zones(:zone_dan_one).x,
					  :y => zones(:zone_dan_one).y,
					  :user_id => 3 )
		assert( !z.save() )
	end

	test "zone with incomplete data is not valid." do
		z = Zone.new( :user_id => 5 )
		assert( !z.save() )

		z = Zone.new( :x => 6 )
		assert( !z.save() )

		z = Zone.new( :y => 6 )
		assert( !z.save() )

		z = Zone.new( :x => 6,
					  :y => 3 )
		assert( !z.save() )

		z = Zone.new( :x => 6,
					  :user_id => 3 )
		assert( !z.save() )

		z = Zone.new( :y => 6,
					  :user_id => 11 )
		assert( !z.save() )
	end

	test "zone with complete data IS valid." do

		user = users(:dave)

	   	a = Zone.new( :x => 1,
			   		  :y => 1,
			   		  :user_id => user.id,
				      :soldiers => 10,
				      :artillery => false,
				      :jamming => false,
		   			  :bunker => false,
		   			  :score => 5 )

		user.total_zones += 1
		user.total_soldiers += a.soldiers
		user.score += a.score

		User.transaction do
			assert( a.save() )
			assert( user.save() )
		end

	    b = Zone.new( :x => 11,
					  :y => 19,
					  :user_id => user.id,
					  :soldiers => 56,
					  :artillery => false,
				      :jamming => true,
		   			  :bunker => false,
		   			  :score => 5 )

		user.total_zones += 1
		user.total_soldiers += b.soldiers
		user.score += b.score
		user.jammingcount += 1

		User.transaction do
			assert( b.save() )
			assert( user.save() )
		end
	end

 	test "zone fields can't be given incorrectly typed data." do
		 b = Zone.new( :x => "L O L i know!!11one",
				 	   :y => "omgwtfbbq",
				 	   :user_id => "string oho!",
		 			   :soldiers => "banana" )

		 assert( !b.save() )		
	end

end
