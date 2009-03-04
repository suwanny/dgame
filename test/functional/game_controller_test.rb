require File.dirname(__FILE__) + '/../test_helper'

#rake test:functionals
#ruby test/functional/game_controller_test.rb
class GameControllerTest < ActionController::TestCase
    # Replace this with your real tests.
    test "the truth" do
        assert true
    end

    test "expand zone with enough turns" do
        bob_zone 	= zones(:bob_zone)
        bob_id 		= bob_zone.user_id
		bob_user	= User.find_by_id(bob_id)

        for o in GameRules::ZONE_EXPANDABLE_AREA_OFFSETS

			assert bob_user.turns >= GameRules::TURNS_CONSUMED_PER_EXPAND, "User does not have enough turns."

            ox = bob_zone.x + o[0]
            oy = bob_zone.y + o[1]
            if Zone.get_zone_at( ox, oy ) != nil         
                next
            end
            retval = get :expand_into_zone, {:targetX => ox, :targetY => oy}, { :user_id => bob_id }
            expanded_zone = Zone.get_zone_at(ox, oy)
            assert_not_nil expanded_zone, retval.body
            assert_equal expanded_zone.user_id, bob_zone.user_id
			
        end
    end

    test "expand zone without enough turns" do
        zone = zones(:zone_carol_b)
        userid = zone.user_id
        assert User.find_by_id(userid).turns < GameRules::TURNS_CONSUMED_PER_EXPAND, "User has enough turns."
        for o in GameRules::ZONE_EXPANDABLE_AREA_OFFSETS
            ox = zone.x + o[0]
            oy = zone.y + o[1]
            if Zone.get_zone_at(ox, oy) != nil
                next
            end
            get :expand_into_zone, {:targetX => ox, :targetY => oy}, { :user_id => userid}
            zone_should_not_expand = Zone.get_zone_at(ox, oy)
            assert_nil zone_should_not_expand
        end
    end

    test "expand zone with enough turns but invalid neighbor" do
        zone = zones(:bob_zone)
        userid = zone.user_id
        assert User.find_by_id(userid).turns >= GameRules::TURNS_CONSUMED_PER_EXPAND, "User does not have enough turns."

        for o in GameRules::ZONE_EXPANDABLE_AREA_OFFSETS
            ox = zone.x + o[0] * 2
            oy = zone.y + o[1] * 2
            if Zone.get_zone_at(ox, oy) != nil
                next
            end
            get :expand_into_zone, {:targetX => ox, :targetY => oy}, { :user_id => userid}
            zone_should_not_expand = Zone.get_zone_at(ox, oy)
            assert_nil zone_should_not_expand
        end
    end

    test "expand zone with enough turns and valid neighbor but existing zone" do
        zone = zones(:zone_dan_two)
        userid = zone.user_id
        user = User.find_by_id(userid)

        for o in GameRules::ZONE_EXPANDABLE_AREA_OFFSETS
            user.turns = GameRules::TURNS_CONSUMED_PER_EXPAND
            user.save
            oldturns = user.turns
            ox = zone.x + o[0]
            oy = zone.y + o[1]
            neighbor_zone = Zone.get_zone_at(ox, oy)
            if neighbor_zone == nil
                next
            end
            neighbor_zone_userid = neighbor_zone.user_id
            get :expand_into_zone, {:targetX => ox, :targetY => oy}, { :user_id => userid}
            zone_should_not_expand = Zone.get_zone_at(ox, oy)
            assert_equal zone_should_not_expand.user_id, neighbor_zone_userid
            assert_equal user.turns, oldturns
        end
    end

    test "train soldier with enough turns" do
        zone 		= zones(:zone_dan_two)
        userid 		= zone.user_id
        user 		= User.find_by_id(userid)
        user.turns 	+= 1
		user.update_turns_by_time()
        user.save
		
        oldsoldiers = user.total_soldiers
        oldturns 	= user.turns

        retval = get :train_soldiers, { :targetX => zone.x, :targetY => zone.y }, { :user_id => userid }
        user2 = User.find_by_id( userid )

        assert_equal oldturns - 1, user2.turns
        #assert_equal oldsoldiers + GameRules::get_soldier_train_count( oldsoldiers, 1 ), user2.total_soldiers, retval.body + " zonex " + zone.x.to_s + " zoney " + zone.y.to_s + " oldolsdfd" + oldsoldiers.to_s
    end

    test "train soldier without enough turns" do
        zone 		= zones(:zone_dan_two)
        userid 		= zone.user_id
        user 		= User.find_by_id(userid)
        user.turns 	= 0
		user.update_turns_by_time()
        user.save
		
        oldsoldiers = user.total_soldiers
        oldturns 	= user.turns
		
        retval = get :train_soldiers, { :targetX => zone.x, :targetY => zone.y }, { :user_id => userid }

		user = User.find_by_id(userid)
		assert_equal oldsoldiers, user.total_soldiers, retval.body
        #assert_equal oldturns, user.turns, retval.body
    end
end
