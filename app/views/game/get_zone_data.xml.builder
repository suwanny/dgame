if @result.type == Zone.type

	# Return success XML.
	# ===================

	xml.status( "code" => 0, "controller_called" => "get_zone_data" ) do
		for z in @result
			if z.user.jammingcount > 0 && z.user_id != @userid
				xml.zone( "x" => z.x, "y" => z.y, "id" => z.user_id, "user" => z.user.name )
			else
				xml.zone( "x" => z.x, "y" => z.y, "id" => z.user_id, "user" => z.user.name,
						  "soldiers" => z.soldiers, "bunker" => z.bunker, "artillery" => z.artillery, "jamming" => z.jamming )
			end
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