class FlashtestController < ApplicationController
    def index
        @user = User.find_by_id(session[:user_id])
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
