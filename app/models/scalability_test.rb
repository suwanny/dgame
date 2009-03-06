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
                user.total_soldiers = 0;
                user.turns = TEST_NEWUSER_TURNS
                user.last_time_login = Time.now
                user.last_time_turns_commit = Time.now
                user.total_zones = 0
                return :user_not_save if not user.save

                newx = TEST_NEWUSER_STARTX + (i - 1) % TEST_NEWUSER_USER_PER_ROW * TEST_NEWUSER_SPANX
                newy = TEST_NEWUSER_STARTY + (i - 1) / TEST_NEWUSER_USER_PER_ROW * TEST_NEWUSER_SPANY
                user.viewport_x = newx
                user.viewport_y = newy

                azone = Zone.get_zone_at(newx, newy)
                if azone == nil
                    azone = Zone.new
                    azone.x = newx
                    azone.y = newy
                    azone.score = 0
                    azone.soldiers = TEST_NEWUSER_SOLDIERS  #default value
                end
                azone.user_id = user.id
                return :azone_not_save if not azone.save

                user.total_zones = 1
                return :user_not_final_save if not user.save
            end
        end
    end

    ## This method is for the scalability tests
    ## randomly expand or attack a zone from the candidates for the current user
    ## mode:
    #        :MODE_EXPAND - only expand
    ##       :MODE_ATTACK - only attack
    ##       :MODE_EXPAND_ATTACK - either expand or attack
    
    def self.random_expand_or_attack(user_id, mode)
        user = User.find_by_id(user_id)
        if user == nil
            return false
        end

        zones_attack = Zone.get_attackable_zones(user_id) if mode != :MODE_EXPAND
        zones_expand = Zone.get_expandable_zones(user_id) if mode != :MODE_ATTACK

        count_attack = (zones_attack) ? zones_attack.size() : 0
        count_expand = (zones_expand) ? zones_expand.size() : 0

        if count_attack == 0 and count_expand == 0
            return :no_candidate
        end

        srand()
        rand_pos = (rand() * (count_attack + count_expand)).to_i

        if rand_pos >= count_attack     # for expand
            zone_to_expand = zones_expand[rand_pos - count_attack]
            for o in GameRules::ZONE_EXPANDABLE_AREA_OFFSETS
                UserZone.train_soldiers(user_id, zone_to_expand[:x] + o[0], zone_to_expand[:y] + o[1])
                UserZone.train_soldiers(user_id, zone_to_expand[:x] + o[0], zone_to_expand[:y] + o[1])
            end
            return UserZone.expand_into_zone( user_id, zone_to_expand[:x], zone_to_expand[:y])
        else
            zone_to_attack = zones_attack[rand_pos]
            for i in (0..(rand() % 4))
                for o in GameRules::ZONE_EXPANDABLE_AREA_OFFSETS
                    UserZone.train_soldiers(user_id, zone_to_attack[:x] + o[0], zone_to_attack[:y] + o[1])
                    UserZone.train_soldiers(user_id, zone_to_attack[:x] + o[0], zone_to_attack[:y] + o[1])
                end
            end
            return UserZone.attack_zone( user_id, zone_to_attack[:x], zone_to_attack[:y])
        end
    end

end