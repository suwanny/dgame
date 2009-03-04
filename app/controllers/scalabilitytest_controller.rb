## This controller includes all the methods for the scalability tests

class ScalabilitytestController < ApplicationController
    ## execute this script by using the url "http://URL/scalabilitytest/add_new_users"
    def add_new_users
        ScalabilityTest.add_new_users(ScalabilityTest::TEST_NEWUSER_COUNT)
        redirect_to( :controller => "users", :action => "ranking" )
    end

    ## execute this script by using the url "http://URL/scalabilitytest/random_expand_zone"
    def random_expand_zone
        @user = User.find_by_id( session[:user_id] )
        if @user == nil
            redirect_to( :controller => "users", :action => "index" )
        else
            @result = ScalabilityTest.random_expand_zone(@user.id)
            if @result != true
                flash[:notice] = @result
            end if
            redirect_to( :controller => "zones", :action => "index" )
        end
    end

    ## execute this script by using the url "http://URL/scalabilitytest/random_attack_zone"
    def random_attack_zone
        @user = User.find_by_id( session[:user_id] )
        if @user == nil
            redirect_to( :controller => "users", :action => "index" )
        else
            @result = ScalabilityTest.random_attack_zone(@user.id)
            if @result != true
                flash[:notice] = @result
            end if
            redirect_to( :controller => "zones", :action => "index" )
        end
    end
end