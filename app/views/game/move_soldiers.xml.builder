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
		eCode = 36
		eText = "User authentication error"
	elsif @result == :database_error
		eCode = 37
		eText = "Database error"
	elsif @result == :not_enough_soldiers
		eCode = 38
		eText = "Not enough soldiers"
	elsif @result == :must_remain_one
		eCode = 39
		eText = "Must keep at least one soldier"
	elsif @result == :zones_not_owned
		eCode = 40
		eText = "User does not own both zones."
	elsif @result == :zones_not_adjacent
		eCode = 41
		eText = "Specified zones are not adjacent."
	elsif @result == :invalid_parameters
		eCode = 42
		eText = "Invalid parameters."
	elsif @result == :not_enough_turns
		eCode = 50
		eText = "Not enough turns."
	end

	xml.status( "code" => eCode ) do
		xml.error( eText )
	end

end