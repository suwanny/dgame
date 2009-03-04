require 'users_helper'

class UsersController < ApplicationController

    def index
        @user = User.find_by_id(session[:user_id])
    end

    def login
        user = User.authenticate( params[:name], params[:password] )
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
            @user.last_time_turns_commit = Time.now

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
        @user_ranking = User.find(:all, :order => 'total_zones DESC, total_soldiers DESC, turns DESC, id'  )
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
        @zone_data = Zone.get_zone_at(5, 5)
        respond_to do |format|
            format.xml { render :xml => @zone_data}
        end
    end

end