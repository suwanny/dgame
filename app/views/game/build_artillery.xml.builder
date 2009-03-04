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
		eCode = 52
		eText = "User authentication error"
	elsif @result == :database_error
		eCode = 53
		eText = "Database error"
	elsif @result == :invalid_parameters
		eCode = 54
		eText = "Invalid parameters."
	elsif @result == :zone_not_owned
		eCode = 55
		eText = "User does not own both zones."
	elsif @result == :already_artillery
		eCode = 56
		eText = "Already an artillery at the target."
	elsif @result == :insufficient_turns
		eCode = 57
		eText = "Not enough turns."
	end

	xml.status( "code" => eCode ) do
		xml.error( eText )
	end

end