## This class includes all the methods for the scalability tests
class ScalabilityTest

    ## constants for the scalabity test methods
    TEST_NEWUSER_TURNS = 100000
    TEST_NEWUSER_COUNT = 100
    TEST_NEWUSER_SOLDIERS = 50
    TEST_NEWUSER_STARTX = 36000
    TEST_NEWUSER_STARTY = 18000
    TEST_NEWUSER_USER_PER_ROW = 10
    TEST_NEWUSER_SPANX = 10
    TEST_NEWUSER_SPANY = 10
    TEST_NEWUSER_PASSWORD = "a"

    ## methods
    public

    ## This method is for the scalability tests
    ## create n test users with the names "a#" (from a1 ~ an) and password "a"
    ## In MYSQL (execute: ruby script/dbconsole) you can execute:
    ##      ALTER TABLE Users AUTO_INCREMENT = starting_value;
    ## to changing the starting id of the users.

    def self.add_new_users(num)
        if num
            n = num
        else
            n = TEST_NEWUSER_COUNT
        end
        for i in (1..n)
            User.transaction do
                user = User.new
                user.name = "a#{i}";
                if User.find_by_name(user.name) != nil
                    next
                end
                user.password = TEST_NEWUSER_PASSWORD;
                user.total_soldiers = TEST_NEWUSER_SOLDIERS;
                user.turns = TEST_NEWUSER_TURNS
                user.last_time_login = Time.now
                user.last_time_turns_commit = Time.now
                user.total_zones = 0
                user.save

                newx = TEST_NEWUSER_STARTX + (i - 1) % TEST_NEWUSER_USER_PER_ROW * TEST_NEWUSER_SPANX
                newy = TEST_NEWUSER_STARTY + (i - 1) / TEST_NEWUSER_USER_PER_ROW * TEST_NEWUSER_SPANY
                user.viewport_x = newx
                user.viewport_y = newy

                azone = Zone.get_zone_at(newx, newy)
                if azone == nil
                    azone = Zone.new
                    azone.x = newx
                    azone.y = newy
                    azone.soldiers = 1  #default value
                end
                azone.user_id = user.id
                azone.save

                user.total_zones = 1
                user.save
            end
        end
    end

    ## This method is for the scalability tests
    ## randomly expand a zone from the candidates of the expandable zones for the current user
    def self.random_expand_zone(user_id)
        user = User.find_by_id(user_id)
        if user == nil
            return false
        end
        zones = Zone.get_expandable_zones(user_id)
        if zones == nil
            return false
        end
        srand()
        zone_to_expand = zones[(rand() * zones.size()).to_i]
        if zone_to_expand == nil
            return false
        end
        result = UserZone.expand_into_zone( user_id, zone_to_expand[:x], zone_to_expand[:y])
        return result
    end

    ## This method is for the scalability tests
    ## randomly attack a zone from the candidates of the attackable zones for the current user
    def self.random_attack_zone(user_id)
        user = User.find_by_id(user_id)
        if user == nil
            return false
        end
        zones = Zone.get_attackable_zones(user_id)
        if zones == nil
            return false
        end
        srand()
        zone_to_attack = zones[(rand() * zones.size()).to_i]
        if zone_to_attack == nil
            return false
        end
        result = UserZone.attack_zone( user_id, zone_to_attack[:x], zone_to_attack[:y])
        return result
    end
end