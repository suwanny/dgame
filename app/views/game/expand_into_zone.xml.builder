if @result.class == Hash

	# Return success XML.
	# ===================

	xml.status( "code" => 0, "result" => true, "time" => ( @result[:time].to_f * 1000.0 ).to_i  ) do
		for z in @result[:czones]
			xml.zone( "x" => z.x, "y" => z.y, "id" => z.user_id, "user" => z.user.name,
				      "soldiers" => z.soldiers, "bunker" => z.bunker, "artillery" => z.artillery, "jamming" => z.jamming )
		end
	end

else

	# Return error XML.
	# =================

	eCode = -1
	eText = "Unknown Error"

	if @result == :user_auth_error
		eCode = 7
		eText = "User authentication error"
	elsif @result == :zone_already_owned
		eCode = 8
		eText = "Zone already owned by a player"
	elsif @result == :not_enough_turns
		eCode = 9
		eText = "Not enough turns"
	elsif @result == :zone_not_touching
		eCode = 10
		eText = "Zone not connected to player territory"
	elsif @result == :database_error
		eCode = 11
		eText = "Database error"
	elsif @result == :not_enough_soldiers
		eCode = 33
		eText = "Not enough soldiers to take zone"
	end

	xml.status( "code" => eCode ) do
		xml.error( eText )
	end

end