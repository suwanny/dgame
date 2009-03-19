if @result.class == Hash

	xml.status( "code" => 0, "controller_called" => "get_costs_at_location", "time" => ( @result[:ctime].to_f * 1000.0 ).to_i ) do
		if @result[:attackcost] != nil
			xml.costs( "artillery" => @result[:artillery], "bunker" => @result[:bunker],
					   "jamming" => @result[:jamming],     "nextsoldier" => @result[:nextsoldier],
					   "attackcost" => @result[:attackcost] )
		elsif @result[:expandcost] != nil
			xml.costs( "artillery" => @result[:artillery], "bunker" => @result[:bunker],
					   "jamming" => @result[:jamming],     "nextsoldier" => @result[:nextsoldier],
					   "expandcost" => @result[:expandcost] )
		else
			xml.costs( "artillery" => @result[:artillery], "bunker" => @result[:bunker],
					   "jamming" => @result[:jamming],     "nextsoldier" => @result[:nextsoldier] )
		end
	end

else

	# Return error XML.
	# =================

	eCode = -1
	eText = "Unknown Error"

	if @result == :invalid_parameters
		eCode = 81
		eText = "Invalid parameters"
	elsif @result == :user_auth_error
		eCode = 82
		eText = "User auth error"
	elsif @result == :database_error
		eCode = 83
		eText = "Database error"
	end

	xml.status( "code" => eCode, "controller_called" => "get_costs_at_location" ) do
		xml.error( eText )
	end

end
