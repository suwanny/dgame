require 'test_helper'

class UsersControllerTest < ActionController::TestCase

    fixtures :users
    fixtures :zones

    if false
        test "index" do
            get :index
            assert_response :success
        end
    end


    test "login" do
        dave = users(:dave)
        post :login, :name => dave.name, :password => 'secret'
        assert_redirected_to :action => "info"
        assert_equal dave.id, session[:user_id]
    end


    test "bad password" do
        dave = users(:dave)
        post :login, :name => dave.name, :password => 'wrong'
        assert_equal "Invalid User/Password.", flash[:notice]
        assert_redirected_to :action => "index"
        #assert_template "login"
    end


    test "logout" do
        dave = users(:dave)
        post :logout
        assert_equal nil, session[:user_id]
        assert_redirected_to :action => "index"
    end


    test "info without user" do
        get :info
        assert_redirected_to :action => "index"
        assert_equal "Please log in.", flash[:notice]
    end


    test "info with user" do
        get :info, {}, { :user_id => users(:dave).id }
        assert_response :success
        assert_template "info"
    end


    test "ranking" do
        get :ranking, {}, { :user_id => users(:dave).id}
        assert_response :success
        assert_template "ranking"
    end


    test "expand territory with enough turns and valid zones UP" do
        bob_zone = zones(:bob_zone)
        get :expand_territory, {:x => bob_zone.x, :y => bob_zone.y - 1}, { :user_id => users(:bob).id}
        assert_equal "You expanded your territory!", flash[:notice]
        assert_redirected_to :controller => 'zones', :action => 'index'
    end

    test "expand territory with enough turns and valid zones DOWN" do
        bob_zone = zones(:bob_zone)
        get :expand_territory, {:x => bob_zone.x, :y => bob_zone.y + 1}, { :user_id => users(:bob).id}
        assert_equal "You expanded your territory!", flash[:notice]
        assert_redirected_to :controller => 'zones', :action => 'index'
    end

    test "expand territory with enough turns and valid zones LEFT" do
        bob_zone = zones(:bob_zone)
        get :expand_territory, {:x => bob_zone.x - 1, :y => bob_zone.y}, { :user_id => users(:bob).id}
        assert_equal "You expanded your territory!", flash[:notice]
        assert_redirected_to :controller => 'zones', :action => 'index'
    end

    test "expand territory with enough turns and valid zones RIGHT" do
        bob_zone = zones(:bob_zone)
        get :expand_territory, {:x => bob_zone.x + 1, :y => bob_zone.y}, { :user_id => users(:bob).id}
        assert_equal "You expanded your territory!", flash[:notice]
        assert_redirected_to :controller => 'zones', :action => 'index'
    end

    test "expand territory with enough turns but invalid zones LeftTop" do
        bob_zone = zones(:bob_zone)
        get :expand_territory, {:x => bob_zone.x - 1, :y => bob_zone.y - 1}, { :user_id => users(:bob).id}
        assert_equal "You can not expand to that area", flash[:notice]
        assert_redirected_to :controller => 'zones', :action => 'index'
    end

    test "expand territory with enough turns but invalid zones LeftBottom" do
        bob_zone = zones(:bob_zone)
        get :expand_territory, {:x => bob_zone.x - 1, :y => bob_zone.y + 1}, { :user_id => users(:bob).id}
        assert_equal "You can not expand to that area", flash[:notice]
        assert_redirected_to :controller => 'zones', :action => 'index'
    end

    test "expand territory with enough turns but invalid zones RightTop" do
        bob_zone = zones(:bob_zone)
        get :expand_territory, {:x => bob_zone.x + 1, :y => bob_zone.y - 1}, { :user_id => users(:bob).id}
        assert_equal "You can not expand to that area", flash[:notice]
        assert_redirected_to :controller => 'zones', :action => 'index'
    end

    test "expand territory with enough turns but invalid zones RightBottom" do
        bob_zone = zones(:bob_zone)
        get :expand_territory, {:x => bob_zone.x + 1, :y => bob_zone.y + 1}, { :user_id => users(:bob).id}
        assert_equal "You can not expand to that area", flash[:notice]
        assert_redirected_to :controller => 'zones', :action => 'index'
    end

    test "expand territory without enough turns" do
        get :expand_territory, {:x => 0, :y => 0}, { :user_id => users(:dave).id}
        assert_equal "You do not have enough turns!", flash[:notice]
        assert_redirected_to :controller => 'zones', :action => 'index'
    end

    test "attack with enough soldiers" do
        get :attack, {:zone => zones(:zone_bob_a).id}, { :user_id => users(:attacker).id}
        assert_equal "You won a battle!", flash[:notice]
        assert_redirected_to :controller => 'zones', :action => 'index'
    end


    test "attack without enough soldiers" do
        get :attack, {:zone => zones(:zone_dave_a).id}, { :user_id => users(:carol).id}
        assert_equal "Not enough soldiers to attack!", flash[:notice]
        assert_redirected_to :controller => 'zones', :action => 'index'
    end


    test "attack without enough turns" do
        get :attack, {:zone => zones(:zone_bob_a).id}, { :user_id => users(:dave).id}
        assert_equal "Not enough turns to attack!", flash[:notice]
        assert_redirected_to :controller => 'zones', :action => 'index'
    end


end
