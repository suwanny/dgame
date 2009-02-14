require 'gamerules'
require 'users_helper'

class UsersController < ApplicationController
  
  def index
    @user = User.find_by_id(session[:user_id])
  end

  def login
    user = User.authenticate( params[:name], params[:password] )
    if user

      #Added by Xin: calculate the turns the user gains between the two logins
      if user.last_time_turns_commit
        @turnsGained = user.get_updated_turns
        if (@turnsGained >= 0)
          user.turns = user.turns + @turnsGained
          user.last_time_turns_commit = \
                    user.last_time_turns_commit + @turnsGained * GameRules::MINUTES_PER_TURN * 60
          flash[:notice] = @turnsGained.to_s + " turns gained at " + user.last_time_turns_commit.to_s + "."
        else
          user.last_time_turns_commit = Time.now
        end

      else #invalid last_time_turns_commit, reinitialize
        user.last_time_turns_commit = Time.now
      end
      user.last_time_login = Time.now

      user.total_soldiers = user.total_soldiers + 1
      if not user.save
        flash[:notice] = "System error: can not update the user turns."
      end

      session[:user_id] = user.id
      session[:user_name] = user.name
      session[:turns] = user.turns
      session[:soldiers] = user.total_soldiers
      session[:alliance] = user.alliance   # for StatesGame
      session[:zones] = user.total_zones        # for StatesGame

      redirect_to( :action => "info" )
    else
      flash[:notice] = "Invalid User/Password."
      redirect_to( :action => "index" )
    end
  end

  def logout
    if session[:user_id]
      flash[:notice] = "Logged out."
    end
    session[:user_id] = nil
    session[:user_name] = nil
    session[:turns] = nil
    session[:soldiers] = nil
    session[:alliance] = nil   # for StatesGame
    session[:zones] = nil        # for StatesGame

    redirect_to( :action => "index" )
  end

  def new
    if request.post?
      redirect_to( :action => "new" ) if not params[:user]
      
      @user         = User.new( params[:user] )
      @user.total_soldiers= GameRules::DEFAULT_STARTING_SOLDIER
      @user.total_zones=0
      @user.turns      = GameRules::DEFAULT_STARTING_TURNS

      @user.alliance = UsersHelper.getAllianceId(params[:alliance]) # StatesGame

      #view port starts from (0,0)
      @user.viewport_x     = 0
      @user.viewport_y     = 0
      @user.last_time_login = Time.now
      if @user.save
        session[:user_id]  = @user.id
        session[:user_name] = @user.name

        # StatesGame - start
        session[:alliance] = @user.alliance
        @user.total_zones = State.count_by_sql "SELECT COUNT(*) FROM states WHERE alliance=#{session[:alliance]}"
        session[:zones] = @user.total_zones
        # StatesGame - end

        redirect_to( :action => "info" )
      else
        flash[:notice]    = @user.errors.full_messages
      end
    else
      @user = User.new
    end
  end

  def info
    @user = User.find_by_id(session[:user_id])

    if !@user
      flash[:notice] = "Please log in."
      redirect_to(:action => "index")
    end
  end

  def ranking
    @user_ranking = User.find(:all, :order => 'total_zones DESC'  )
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @user_ranking }
    end
  end

  def game
  end

  def zone_xml
    @user = User.find_by_id(session[:user_id])
    #@zone_data = Zone.find_zones_in_view_xml(0,5,0,5)
    @zone_data = Zone.get_zone_from_coordinates(5, 5)
    respond_to do |format|
      format.xml { render :xml => @zone_data}
    end
  end

  def attack
    @zone = Zone.find(params[:zone])
    @defender = User.find_by_id(@zone.user_id)
    @attacker = User.find_by_id(session[:user_id])

    if not @attacker
      flash[:notice] = "Please log in!"
      redirect_to(:controller => 'users', :action => 'index')
      return
    end

    if not @defender
      flash[:notice] = "No defender in that zone!"
      redirect_to(:controller => 'zones', :action => 'index')
      return
    end

    if not @zone
      flash[:notice] = "Zone not valid!"
      redirect_to(:controller => 'zones', :action => 'index')
      return
    end

    #attack fails
    if @defender.total_soldiers >= @attacker.total_soldiers
      flash[:notice] = "Not enough soldiers to attack!"
      redirect_to(:controller => 'zones', :action => 'index')
    else
      if @attacker.new_turns_after_attacking < 0
        flash[:notice] = "Not enough turns to attack!"
        redirect_to(:controller => 'zones', :action => 'index')
      else
        @zone.user_id = @attacker.id
        @zone.save

        #update soldier/zones/turns count for users in user model
        @attacker.total_soldiers = @attacker.new_total_soldiers_after_battle
        @attacker.total_zones = Zone.get_total_zones_for_user(@attacker.id)
        @attacker.turns = @attacker.new_turns_after_attacking
        @attacker.try_save

        @defender.total_soldiers = @defender.new_total_soldiers_after_battle
        @defender.total_zones = Zone.get_total_zones_for_user(@defender.id)
        @defender.try_save

        flash[:notice] = "You won a battle!"
        redirect_to(:controller => 'zones', :action => 'index')
      end
    end
  end

  def expand_territory
    @zone = Zone.new
    @user = User.find_by_id(session[:user_id])

    if not @user
      flash[:notice] = "Please log in!"
      redirect_to(:controller => 'users', :action => 'index')
      return
    end

    if not params[:x] or not params[:y]
      flash[:notice] = "Please sepecify a zone!"
      redirect_to(:controller => 'zones', :action => 'index')
      return
    end

    if @user.new_turns_after_expanding < 0
      flash[:notice] = "You do not have enough turns!"
      redirect_to(:controller => 'zones', :action => 'index')
    else

      @zone.x = params[:x]
      @zone.y = params[:y]

      # check if the (x,y) is an expandable zone for this user
      neighbor_zones = Zone.find_zones_in_view(@zone.x - 1, @zone.x + 1, @zone.y - 1, @zone.y + 1)
      logger.info "XIN_DEBUG: neighbor_zones:#{neighbor_zones.inspect}"

      Zone.remark_expandable_zones(@zone.x - 1, @zone.x + 1, @zone.y - 1, @zone.y + 1,
          neighbor_zones, session[:user_id])
      if (not neighbor_zones \
                or ((not neighbor_zones[0][1] or neighbor_zones[0][1].user_id != @user.id) \
                    and (not neighbor_zones[2][1] or neighbor_zones[2][1].user_id != @user.id)\
                    and (not neighbor_zones[1][0] or neighbor_zones[1][0].user_id != @user.id)\
                    and (not neighbor_zones[1][2] or neighbor_zones[1][2].user_id != @user.id)\
                    )
      )
        flash[:notice] = "You can not expand to that area"
        redirect_to(:controller => 'zones', :action => 'index')
        return
      end
      @zone.user_id = session[:user_id]
      @zone.save

      @user.turns = @user.new_turns_after_expanding
      @user.total_zones = Zone.get_total_zones_for_user(@user.id)
      @user.try_save

      flash[:notice] = "You expanded your territory!"
      redirect_to(:controller => 'zones', :action => 'index')
    end
  end
end