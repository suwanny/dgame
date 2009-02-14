require 'test_helper'

class ZonesControllerTest < ActionController::TestCase
  test "should get index" do
    #get :index
    #assert_response :success
    #assert_not_nil assigns(:zones)
  end

  test "should get new" do
    #get :new
    #assert_response :success
  end

  test "should create zone" do
    #assert_difference('Zone.count') do
    #  post :create, :zone => { }
    #end

    #assert_redirected_to zone_path(assigns(:zone))
  end

  test "should show zone" do
    #get :show, :id => zones(:one).id
    #assert_response :success
  end

  test "should get edit" do
    #get :edit, :id => zones(:one).id
    #assert_response :success
  end

  test "should update zone" do
    #put :update, :id => zones(:one).id, :zone => { }
    #assert_redirected_to zone_path(assigns(:zone))
  end

  test "should destroy zone" do
      assert_difference('Zone.count', -1) do
          delete :destroy, :id => zones(:zone_dave_a).id
      end
      assert_redirected_to zones_path
  end


  test "expand to new zone" do

  end


    


end
