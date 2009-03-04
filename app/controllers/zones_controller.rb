class ZonesController < ApplicationController
    # GET /zones
    # GET /zones.xml
    def index
        #the displaying range of the world
        @user = User.find_by_id(session[:user_id])
        if (!params[:x1])
            if @user != nil
                @x_min = [@user.viewport_x.to_i - 20, 0].max
            else
                @x_min = 0
            end
        else
            @x_min = params[:x1].to_i
        end

        if (!params[:x2])
            @x_max = @x_min + 39
        else
            @x_max = params[:x2].to_i
        end

        if (!params[:y1])
            if @user != nil
                @y_min = [@user.viewport_y.to_i - 15, 0].max
            else
                @y_min = 0
            end
        else
            @y_min = params[:y1].to_i
        end

        if (!params[:y2])
            @y_max = @y_min + 29
        else
            @y_max = params[:y2].to_i
        end

        if (!params[:w])
            @grid_w = 20   # the width of each grid
        else
            @grid_w = [[25, params[:w].to_i].min, 8].max   # the width of each grid
        end

        @existing_zones = Zone.find_zones_in_view_xml(@x_min, @x_max, @y_min, @y_max)
        if @user != nil
            @expandable_zones = Zone.get_expandable_zones_in_view(@user.id, @x_min, @x_max, @y_min, @y_max)
            @attackable_zones = Zone.get_attackable_zones_in_view(@user.id, @x_min, @x_max, @y_min, @y_max)
        end
        @users_in_area = Zone.find_users_in_area(@existing_zones)
#    @zones = Zone.find(:all)

        respond_to do |format|
            format.html # index.html.erb
            format.xml  { render :xml => @zones }
        end
    end

    # GET /zones/1
    # GET /zones/1.xml

    def show
        if (params[:id] == "attack")
            redirect_to(:action =>"edit", :id => params[:zone])
        end
    end

    # GET /zones/new
    # GET /zones/new.xml

    def new
        @zone = Zone.new
        @user = User.find_by_id(session[:user_id])

        if not @user
            flash[:notice] = "No user information!"
            redirect_to(:action =>"index")
        end

        if @user.new_turns_after_expanding < 0
            flash[:notice] = "No enough turn to expand!"
            redirect_to(:action =>"index")
        else
            respond_to do |format|
                format.html # new.html.erb
                format.xml  { render :xml => @zone }
            end
        end
    end

    # GET /zones/1/edit

    def edit
        @zone = Zone.find(params[:id])
        @user = User.find_by_id(session[:user_id])
        if @user.new_turns_after_attacking < 0
            flash[:notice] = "No enough turn to attack!"
            redirect_to(:action =>"index")
        end
    end

    # POST /zones
    # POST /zones.xml

    def create
        @zone = Zone.new(params[:zone])
        @user = User.find_by_id(session[:user_id])
        @user.turns = @user.new_turns_after_expanding
        @user.try_save

        respond_to do |format|
            if @zone.save
                @user = User.find_by_id(session[:user_id])
                @user.turns = @user.new_turns_after_expanding
                @user.total_zones = Zone.get_total_zones_for_user(@user.id)
                @user.try_save

                flash[:notice] = 'Zone was successfully created.'
                format.html { redirect_to(zones_url) }
                format.xml  { render :xml => @zone, :status => :created } #, :location => @game_state
                #format.html { redirect_to(@zone) }
                #format.xml  { render :xml => @zone, :status => :created, :location => @zone }
            else
                format.html { render :action => "new" }
                format.xml  { render :xml => @zone.errors, :status => :unprocessable_entity }
            end
        end
    end

    # PUT /zones/1
    # PUT /zones/1.xml

    def update
        @zone = Zone.find(params[:id])
        @user = User.find_by_id(session[:user_id])
        @user.turns = @user.new_turns_after_attacking
        @user.try_save

        respond_to do |format|
            if @zone.update_attributes(params[:zone])
                @user.total_zones = Zone.get_total_zones_for_user(@user.id)
                @user.turns = @user.new_turns_after_attacking
                @user.try_save
                flash[:notice] = 'Zone was successfully attacked.'
                format.html { redirect_to(zones_url) }
                format.xml  { head :ok }
            else
                format.html { render :action => "edit" }
                format.xml  { render :xml => @zone.errors, :status => :unprocessable_entity }
            end
        end

    end

    # DELETE /zones/1
    # DELETE /zones/1.xml

    def destroy
        @zone = Zone.find(params[:id])
        @zone.destroy

        respond_to do |format|
            format.html { redirect_to(zones_url) }
            format.xml  { head :ok }
        end
    end
end
