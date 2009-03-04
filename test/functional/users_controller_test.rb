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

end
