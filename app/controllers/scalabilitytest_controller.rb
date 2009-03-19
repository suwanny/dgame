require 'memcache_util.rb'

## This controller includes all the methods for the scalability tests
class ScalabilitytestController < ApplicationController
    ## execute this script by using the url "http://URL/scalabilitytest/add_new_users"
    def add_new_users
        flash[:notice] = ScalabilityTest.add_new_users(ScalabilityTest::TEST_NEWUSER_COUNT)
        redirect_to( :controller => "users", :action => "ranking" )
    end

    ## execute this script by using the url "http://URL/scalabilitytest/random_expand_zone"
    def random_expand_zone
        @user = User.find_by_name(get_random_user_name)
        if @user == nil
            redirect_to( :controller => "users", :action => "index" )
        else
            @result = ScalabilityTest.random_expand_or_attack(@user.id, :MODE_EXPAND)
            flash[:notice] = @result
            redirect_to( :controller => "zones", :action => "index" )
        end
    end

    ## execute this script by using the url "http://URL/scalabilitytest/random_attack_zone"
    def random_attack_zone
        @user = User.find_by_name(get_random_user_name)
        if @user == nil
            redirect_to( :controller => "users", :action => "index" )
        else
            @result = ScalabilityTest.random_expand_or_attack(@user.id, :MODE_ATTACK)
            if @result != true
                flash[:notice] = @result
            end
            redirect_to( :controller => "zones", :action => "index" )
        end
    end

    ## execute this script by using the url "http://URL/scalabilitytest/random_expand_or_attack"
    def random_expand_or_attack
        @user = User.find_by_name(get_random_user_name)
        if @user == nil
            redirect_to( :controller => "users", :action => "index" )
        else
            @result = ScalabilityTest.random_expand_or_attack(@user.id, :MODE_EXPAND_ATTACK)
            if @result != true
                flash[:notice] = @result
            end
            redirect_to( :controller => "zones", :action => "index" )
        end
    end

    ## execute this script by using the url "http://URL/scalabilitytest/random_view"
    def random_view
        if GameController::USE_MEMCACHED
            xprev = Cache.get("scalability_test_random_view_x")
            yprev = Cache.get("scalability_test_random_view_y")
            if (xprev != nil && yprev != nil)
                xpos = xprev
                ypos = yprev
            else
                xpos = (rand() * 100 + ScalabilityTest::TEST_NEWUSER_STARTX).to_i
                ypos = (rand() * 100 + ScalabilityTest::TEST_NEWUSER_STARTY).to_i
                Cache.put("scalability_test_random_view_x", xpos, 30)
                Cache.put("scalability_test_random_view_y", ypos, 30)
            end
        else
            xpos = (rand() * 100 + ScalabilityTest::TEST_NEWUSER_STARTX).to_i
            ypos = (rand() * 100 + ScalabilityTest::TEST_NEWUSER_STARTY).to_i
        end
        if GameController::USE_MEMCACHED
            if Zone.MEMCACHED_ViewportSame(xpos, xpos + ScalabilityTest::VIEW_W, ypos, ypos + ScalabilityTest::VIEW_H)    
                @zonedata_str = Zone.MEMCACHED_LoadZoneXML
            else
                @zonedata = Zone.find_zones_in_view_xml(xpos, xpos + ScalabilityTest::VIEW_W, ypos, ypos + ScalabilityTest::VIEW_H)
                @zonedata_str = Zone.MEMCACHED_SaveZoneXML(xpos, xpos + ScalabilityTest::VIEW_W, ypos, ypos + ScalabilityTest::VIEW_H, @zonedata)
            end
        else
            @zonedata = Zone.find_zones_in_view_xml(xpos, xpos + ScalabilityTest::VIEW_W, ypos, ypos + ScalabilityTest::VIEW_H)
        end
        #cache will be effective for 30 seconds
        respond_to do |format|
            format.xml { render :layout => false}
        end
        #    redirect_to( :controller => "users", :action => "index" )
    end

    ## execute this script by using the url "http://URL/scalabilitytest/random_operation"
    def random_operation
        @user = User.find_by_id( session[:user_id] )
        if @user == nil
            redirect_to( :controller => "users", :action => "index" )
        else
            if (@user.avg_soldiers_per_zone < 1)
                #UserZone.train_soldiers(@user.id, GameRules::TURNS_PER_TRAINING)
            else
                @result = ScalabilityTest.random_expand_or_attack(@user.id, :MODE_EXPAND_ATTACK)
                if @result != true
                    flash[:notice] = @result
                end
            end
            redirect_to( :controller => "zones", :action => "index" )
        end
    end

    ## execute tthis script by using the url "http://URL/scalabilitytest/random_login"
    def random_login
        if random_login_internal
            redirect_to( :controller => "users", :action => "info" )
        else
            redirect_to( :controller => "users", :action => "index" )
        end
    end

    ## clear the cache
    def clear_cache
        Cache.flush_all
        s = []
        x1 = Cache.get("Effective_view_xmin")
        x2 = Cache.get("Effective_view_xmax")
        y1 = Cache.get("Effective_view_ymin")
        y2 = Cache.get("Effective_view_ymax")
        s = "Effective_view_xmin=" + x1.to_s + ", Effective_view_xmax=" + x2.to_s + ", Effective_view_ymin=" + y1.to_s + ", Effective_view_ymax=" + y2.to_s
        respond_to do |format|
            format.xml { render :xml => s}
        end
    end
    
    ## execute this script by using the url "http://URL/scalabilitytest/create_10000_random_zone_records"
    def create_10000_random_zone_records()
        for time in (1..100)
            random_login_internal
            for i in (1..100)
                @user = User.find_by_id( session[:user_id] )
                if @user == nil
                    redirect_to( :controller => "users", :action => "index" )
                else
                    if (@user.avg_soldiers_per_zone < 1)
                    #    UserZone.train_soldiers(@user.id, GameRules::TURNS_PER_TRAINING)
                    else
                        @result = ScalabilityTest.random_expand_or_attack(@user.id, :MODE_EXPAND_ATTACK)
                        if @result != true
                            flash[:notice] = @result
                        end
                    end
                end
            end
        end
    end

private

    def random_login_internal
        user_name = get_random_user_name
        user = User.authenticate( user_name, ScalabilityTest::TEST_NEWUSER_PASSWORD )
        if user
            oldTurns = user.turns
            user.update_turns_by_time()
            user.update_last_login()
            successMsg = "#{user.turns - oldTurns} turns gained after login."
            if not user.save
                flash[:notice] = user.get_error_msg
                flash[:notice] += "Can not update user data!"
            else
                flash[:notice] = successMsg
            end

            session[:user_id] = user.id
            session[:user_name] = user.name
            session[:turns] = user.turns
            session[:soldiers] = user.total_soldiers
            session[:alliance] = user.alliance   # for StatesGame
            session[:zones] = user.total_zones        # for StatesGame
            return true
        else
            flash[:notice] = "Invalid User/Password."
            return false
        end
    end

    def get_random_user_name
        return "a"+(rand() * ScalabilityTest::TEST_NEWUSER_COUNT + 1).to_i.to_s
    end
end