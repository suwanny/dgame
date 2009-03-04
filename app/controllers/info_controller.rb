require 'users_helper'

class InfoController < ApplicationController
  
  def test
    @user = User.find_by_id(session[:user_id])
    @zone = Zone.get_zone_at(5, 5)
    respond_to do |format|
      format.xml { render :layout => false}
    end
  end
  
  
  
  
  # Next three functions are prototypes for talking to Flash applet
  # We need to port more game functionality to them (Arvin, Feb 14)
  
  # Return a block of cells
  def get_zones
    @user = User.find_by_id(session[:user_id])
    @zone_data = Zone.find_zones_in_view_xml(params[:x1],params[:x2],params[:y1],params[:y2])
    respond_to do |format|
      format.xml { render :xml => @zone_data}
    end
  end
  
  # Return the user info
  def get_userinfo
  	@user = User.find_by_id(session[:user_id])
  	respond_to do |format|
      format.xml { render :xml => @user}
    end
  end
  
  # Put a move, (just capture a cell NO CHECKS SO THIS THIS IS WEIRD)
  # Returns XML list of the data in the specified viewport
  def put_move
    @user = User.find_by_id(session[:user_id])
    
    @zone = Zone.new
	
	@zone.x = params[:x]
    @zone.y = params[:y]
    
    @zone.user_id = session[:user_id]
    @zone.save
    
    @zone_data = Zone.find_zones_in_view_xml(params[:x1],params[:x2],params[:y1],params[:y2])
    respond_to do |format|
      format.xml { render :xml => @zone_data}
    end
  end

end
