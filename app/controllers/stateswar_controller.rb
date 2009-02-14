#require 'users_helper'

# States Ware Game Controller
# Fully Ajaxy Google Map Gaem
# This consists of JavaScript Objects and Ajax style communiction with Rails
# Author: Soo Hwan Park

class StateswarController < ApplicationController
  def index
    @num_solders = [1, 2, 5, 10, 20]
    @my_states = State.myStates(session[:alliance])  if session[:alliance]
    #@states = State.find(:all, :conditions => { :user_id >= 0 })
    #@states = State.getStates
    @states = State.find(:all)
    @team = UsersHelper.getAllianceStr session[:alliance] # StatesGame
  end

  # Methods for Asynchronous View of the Game state
  # refresh game board periodically ..

  def refresh_game
    logger.info "** DEBUG: refresh game state #{session[:user_name]}"
    render :partial => 'gmap_refresh'
  end

  def refresh_gmap_view
    @states = State.find(:all)
    render(:partial => 'action_expand')
  end

  def refresh_profile_info
    @user = User.find_by_id(session[:user_id])
    session[:turns] = @user.turns
    session[:soldiers] = @user.total_soldiers
    session[:alliance] = @user.alliance
    @user.total_zones = State.count_by_sql "SELECT COUNT(*) FROM states WHERE alliance=#{session[:alliance]}"
    session[:zones] = @user.total_zones

    @team = UsersHelper.getAllianceStr session[:alliance] # StatesGame
    render(:partial => 'profile_info')
  end

  def refresh_my_states
    @my_states = State.myStates(session[:alliance])
    render(:partial => 'alliance_states' )
  end


  # Methods for Manipulating Soldiers

  def train_soldiers
    logger.info "request soldiers #{params[:soldiers]}, current turns #{session[:turns]}"
    @user = User.find_by_id(session[:user_id])
    @user.train_soldier(params[:soldiers])
    session[:turns] = @user.turns
    session[:soldiers] = @user.total_soldiers
    logger.info "result of training soldiers: #{session[:turns]} and turns #{session[:turns]}"

    @team = UsersHelper.getAllianceStr session[:alliance] # StatesGame
    render(:partial => 'profile_info')
  end

  def add_soldier
    # remove num of soldier from the user
    # add a soldier to the state
    num_soldiers = params[:soldiers].to_i
    logger.info "** DEBUG ADD SOLDIER #{params[:state_name]}, USER #{session[:user_name]}"
    if params[:state_name].length == 2
      @user = User.find_by_id(session[:user_id])
      @state = State.find_by_state_name(params[:state_name])
      if @user.total_soldiers > num_soldiers and @state
        @user.total_soldiers -= num_soldiers
        @state.soldiers += num_soldiers
        @user.save
        @state.save

        # redraw game view.. and others..
        @states = State.find(:all)
        render(:partial => 'action_expand')
      end
    end
  end

  def sell_soldier
    num_soldiers = params[:soldiers].to_i
    obtained_turns = num_soldiers * (GameRules::TURNS_PER_SOLDIER / 2)
    logger.info "** DEBUG SELL SOLDIER #{num_soldiers}, USER #{session[:user_name]}"

    flash[:notice] = "SELL SOLDIER #{num_soldiers}, GOT TURNS #{obtained_turns}"
    @user = User.find_by_id(session[:user_id])
    if @user.total_soldiers > num_soldiers
      @user.total_soldiers -= num_soldiers
      @user.turns += obtained_turns
      @user.save

      # redraw game view.. and others..
      session[:turns] = @user.turns
      session[:soldiers] = @user.total_soldiers
      @user.total_zones = State.count_by_sql "SELECT COUNT(*) FROM states WHERE alliance=#{session[:alliance]}"
      session[:zones] = @user.total_zones

      @team = UsersHelper.getAllianceStr session[:alliance] # StatesGame
      render(:partial => 'profile_info')
    end
  end

  # Methods for Game Actions ..
  # SooHwan - attack a region of states

  def attack_region
    initial_soldier_num = 1
    logger.info "** DEBUG: ATTACK #{params[:state_name]}, attack soldiers #{params[:soldiers]}"
    num_soldiers = params[:soldiers].to_i
    if params[:state_name].length == 2
      @user = User.find_by_id(session[:user_id])
      @state = State.find_by_state_name(params[:state_name])
      if @user.total_soldiers > num_soldiers and @user.turns > GameRules::TURNS_CONSUMED_PER_ATTACK and @state
        @user.total_soldiers -= num_soldiers
        @user.total_soldiers -= initial_soldier_num
        @user.turns -= GameRules::TURNS_CONSUMED_PER_ATTACK
        @user.save
        
        if num_soldiers > 2 * @state.soldiers
          # win..
          flash[:notice] = "Attack Result: You Won"
          logger.info "** DEBUG: ATTACK_RESULT #{params[:state_name]} WON AND CONQUER #{params[:state_name]}"
          @state.user_id = @user.id
          @state.alliance = @user.alliance
          @state.soldiers = initial_soldier_num
          @state.updated_at = Time.now
          @user.total_zones = State.count_by_sql "SELECT COUNT(*) FROM states WHERE alliance= #{session[:alliance]}"
          session[:zones] = @user.total_zones
          @state.save
        else
          # lose
          flash[:notice] = "Attack Result: You lost"
          logger.info "** DEBUG: ATTACK_RESULT #{params[:state_name]} LOST!!!"
          @state.user_id = @user.id
        end
      else
        flash[:notice] = "ATTACK Result: You DON'T HAVE ENOUGH TURNS OR SOLDIERS TO CONQUER"
        logger.info "** DEBUG: ATTACK_RESULT #{params[:state_name]} You DON'T HAVE ENOUGH TURNS OR SOLDIERS TO CONQUER!!!"
      end
    end

    #@state = State.find_by_state_name(params[:state_name])
    logger.debug "** DEBUG: state"
    @attacked_state = State.find_by_state_name(params[:state_name])
    @states = State.find(:all)
    logger.info "** DEBUG: error states is null" if @states == nil
    render(:partial => 'action_expand')
  end

  #SooHwan

  def expand_region
    logger.info "** DEBUG: expand #{params[:state_name]}, user #{session[:user_name]}"
    initial_soldier_num = 1

    #state_name = params[:state_name]
    if params[:state_name].length == 2
      @user = User.find_by_id(session[:user_id])
      @state = State.find_by_state_name(params[:state_name])
      if @state == nil
        @state = State.new()
        #update
        @state.state_name = params[:state_name]
        @state.user_id = @user.id
        @state.alliance = @user.alliance
        @state.soldiers = initial_soldier_num
        @state.created_at = Time.now
        @state.updated_at = Time.now
        @state.save

        @user.turns -= GameRules::TURNS_CONSUMED_PER_EXPAND
        @user.total_soldiers -= initial_soldier_num
        @user.total_zones = State.count_by_sql "SELECT COUNT(*) FROM states WHERE alliance= #{session[:alliance]}"
        session[:zones] = @user.total_zones
        @user.save
      else
        # attack..
        if @state.alliance == -1 # not owned
          logger.info "** DEBUG: Expand State: #{params[:state_name]}, Attacker: #{session[:alliance]}"
          @state.state_name = params[:state_name]
          @state.user_id = @user.id
          @state.alliance = @user.alliance
          @state.soldiers = initial_soldier_num
          @state.updated_at = Time.now
          @state.save

          @user.turns -= GameRules::TURNS_CONSUMED_PER_EXPAND
          @user.total_soldiers -= initial_soldier_num
          @user.total_zones = State.count_by_sql "SELECT COUNT(*) FROM states WHERE alliance= #{session[:alliance]}"
          session[:zones] = @user.total_zones
          @user.save

        elsif @state.alliance != @user.alliance
          # decision equation..
          logger.info "** DEBUG: Attack: #{params[:state_name]}, Attacker: #{session[:alliance]}, Owner: #{@state.alliance}"
        end
      end
    end

    @states = State.find(:all)
    logger.info "** DEBUG: error states is null" if @states == nil
    render(:partial => 'action_expand')
    #render :json => @states.to_json
    #    render :update do |page|
    #      logger.info "update page call #{page}"
    #      page.replace_html 'message', "<script type='text/javascript'>alert('expand #{params[:state_name]}');</script>"
    #    end
  end

  def withdraw_region
    logger.info "** DEBUG: withdraw_region #{params[:state_name]}, current turns #{session[:user]}"
    #state_name = params[:state_name]
    if params[:state_name].length == 2
      @user = User.find_by_id(session[:user_id])
      @state = State.find_by_state_name(params[:state_name])
      if @state
        num_soldiers = @state.soldiers;
        @state.user_id = -1
        @state.alliance = -1
        @state.soldiers = 0
        @state.updated_at = Time.now
        @state.save
      end
      @user.total_zones = State.count_by_sql "SELECT COUNT(*) FROM states WHERE alliance= #{session[:alliance]}"
      session[:zones] = @user.total_zones
      @user.save


    end

    @states = State.find(:all)
    logger.info "** DEBUG: error states is null" if @states == nil
    flash[:notice] = "Attack Result: error states is null"
    redirect_to(:action => 'index')
    #render(:partial => 'action_expand')
  end


end
