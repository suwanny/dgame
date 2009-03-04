require 'test_helper'

class UserTest < ActiveSupport::TestCase

    fixtures :users

    test "invalid with empty attributes" do
        user = User.new
        assert !user.valid?
        assert user.errors.invalid?(:name)
    end

    test "default value for a new record" do
        user = User.new
        assert user.total_soldiers >= 0
        assert user.total_zones >=0
    end

    test "unique name" do
        user = User.new(:name => users(:dave).name)
        assert !user.save
        assert_equal "has already been taken", user.errors.on(:name)
    end

    test "positive soldier count" do
        dave = users(:dave)
		tSoldiers = dave.total_soldiers
        assert dave.total_soldiers
        dave.total_soldiers = -1
        assert !dave.valid?
        #assert_equal "must be greater than or equal to 0", dave.errors.on(:total_soldiers)
        dave.total_soldiers = tSoldiers
        assert dave.valid?, dave.errors.full_messages
    end

    test "positive turns count" do
        dave = users(:dave)
        assert dave.turns
        dave.turns = -1
        assert !dave.valid?
        assert_equal "must be greater than or equal to 0", dave.errors.on(:turns)
        dave.turns = 0
        assert dave.valid?, dave.errors.full_messages
    end

    test "update turns after login" do
        dave = users(:dave)
        dave.last_time_turns_commit = "Thu Feb 14 11:10:26 -0500 2008"
        assert dave.get_updated_turns()
    end

    test "update turns after expand" do
        dave = users(:dave)
        dave.turns = 5
        assert dave.new_turns_after_expanding
        dave.turns = 20
        assert dave.new_turns_after_expanding
    end

    test "update turns after attack" do
        dave = users(:dave)
        dave.turns = 5
        assert dave.new_turns_after_attacking
        dave.turns = 50
        assert dave.new_turns_after_attacking
    end

    test "update total soldiers after battle" do
        dave = users(:dave)
        dave.total_soldiers = 5
        assert_equal 0, dave.new_total_soldiers_after_battle
        dave.total_soldiers = 100
        assert dave.new_total_soldiers_after_battle
    end

    test "cannot set turn count to less than zero" do
        d = users(:dave)
        d.turns = -1
        assert !d.save()
    end
end