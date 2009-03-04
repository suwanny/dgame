class MainController < ApplicationController

	def index
        @user = User.find_by_id( session[:user_id] )
	end

	def login
		user = User.authenticate( params[:name], params[:password] )
        if user
            session[:user_id] 	= user.id
            redirect_to( :action => "index", :controller => "game" )
        else
            flash[:notice] 		= "Invalid User/Password."
            redirect_to( :action => "index" )
        end
	end

	def new
		if request.post?
            redirect_to( :action => "new" ) if not params[:user]

            @user         					= User.new( params[:user] )
            @user.total_soldiers			= GameRules::DEFAULT_STARTING_SOLDIER
            @user.total_zones				= 0
            @user.turns      				= GameRules::DEFAULT_STARTING_TURNS
            @user.viewport_x     			= 0
            @user.viewport_y     			= 0
            @user.last_time_login 			= Time.now
            @user.last_time_turns_commit 	= Time.now

            if @user.save
                session[:user_id]  			= @user.id
                redirect_to( :action => "index", :controller => "game" )
            else
                flash[:notice]    			= @user.errors.full_messages
            end
        else
            @user 							= User.new
        end
	end

	def logout
		
	end

end