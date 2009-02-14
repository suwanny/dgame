require 'gamerules'

class FlashtestController < ApplicationController
  def index
    @user = User.find_by_id(session[:user_id])
  end


  #dave - preprocessing on zone: if user occupies, it will be an attack, otherwise an expand
  def analyze_zone
    @user = User.find_by_id(session[:user_id])
    @zone = Zone.get_zone_from_coordinates(5, 5)#params[:x], params[:y])

    if !@zone    #expand
      redirect_to(:controller => "users", :action => "expand_territory")
    else         #attack
      redirect_to(:controller => "users", :action => "attack")
    end
  end


  # Get the gamestate
  def get_gamestate
  end

  # Get the gridstate
  def get_gridstate
  end

  # Set a move
  def put_move
    @flashtest_parameter_store = params[:flashtest_parameter]
  end
end
