if @result.class == Hash

	# Return success XML.
	# ===================

	xml.status( "code" => 0, "result" => @result[:result], "time" => ( @result[:time].to_f * 1000.0 ).to_i ) do
		for z in @result[:czones]
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
	
	if @result == :invalid_defending_zone
		eCode = 3
		eText = "Invalid defending zone"
	elsif @result == :user_lookup_error
		eCode = 4
		eText = "User lookup error"
	elsif @result == :no_attackers
		eCode = 5
		eText = "Invalid attacking zone"
	elsif @result == :database_error
		eCode = 6
		eText = "Database error"
	elsif @result == :invalid_params
		eCode = 30
		eText = "Invalid Parameters"
	elsif @result == :same_user
		eCode = 31
		eText = "Can't attack self!"
	elsif @result == :not_enough_soldiers
		eCode = 32
		eText = "Not enought soldiers to attack"
	end

	xml.status( "code" => eCode ) do
		xml.error( eText )
	end

end