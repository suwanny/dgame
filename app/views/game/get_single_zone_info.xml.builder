if @result != nil

	# Return success XML.
	# ===================

	xml.status( "code" => 0 ) do
		if @result.user.jammingcount > 0 && @result.user_id != @userid
			xml.zone( "x" => @result.x, "y" => @result.y, "id" => @result.user_id, "user" => @result.user.name )
		else
			xml.zone( "x" => @result.x, 					"y" => @result.y,
					  "id" => @result.user_id, 				"user" => @result.user.name,
					  "soldiers" => @result.soldiers, 		"bunker" => @result.bunker,
					  "artillery" => @result.artillery, 	"jamming" => @result.jamming )
		end
	end

else

	# Return error XML.
	# =================

	eCode = -1
	eText = "Unknown Error"

	if @result == :invalid_params
		eCode = 12
		eText = "Invalid parameters"
	elsif @result == :database_error
		eCode = 13
		eText = "Database error"
	end

	xml.status( "code" => eCode ) do
		xml.error( eText )
	end

end