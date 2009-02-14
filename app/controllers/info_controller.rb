class InfoController < ApplicationController
  def test
    @user = User.find_by_id(session[:user_id])
    @zone = Zone.get_zone_from_coordinates(5, 5)
    respond_to do |format|
      format.xml { render :layout => false}
    end
  end

end
