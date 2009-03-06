if @result.class == Hash

	# Return success XML.
	# ===================

	xml.status( "code" => 0, "result" => true, "time" => ( @result[:time].to_f * 1000.0 ).to_i, "controller_called" => "build_jamming_tower"  ) do
		for z in @result[:czones]
			xml.zone( "x" => z.x, "y" => z.y, "id" => z.user_id, "user" => z.user.name,
				      "soldiers" => z.soldiers, "bunker" => z.bunker, "artillery" => z.artillery, "jamming" => z.jamming )
		end

		auser = @result[:user]

		xml.userinfo( "name" 			=> auser.name, 				"score" 		=> auser.score,
					  "info" 			=> auser.public_info,		"email"			=> auser.email,
					  "color_r"			=> auser.color_r,			"color_g"   	=> auser.color_g,
				      "color_b"			=> auser.color_b,			"turns"			=> auser.turns,
			 	      "total_soldiers"	=> auser.total_soldiers,	"total_zones"	=> auser.total_zones,
					  "viewport_x"		=> auser.viewport_x,		"viewport_y"	=> auser.viewport_y )
	end

else

	# Return error XML.
	# =================

	eCode = -1
	eText = "Unknown Error"

	if @result == :user_auth_error
		eCode = 75
		eText = "User authentication error"
	elsif @result == :database_error
		eCode = 76
		eText = "Database error"
	elsif @result == :invalid_parameters
		eCode = 77
		eText = "Invalid parameters."
	elsif @result == :zone_not_owned
		eCode = 78
		eText = "User does not own both zones."
	elsif @result == :already_jtower
		eCode = 79
		eText = "Already a jamming tower at the target."
	elsif @result == :insufficient_turns
		eCode = 80
		eText = "Not enough turns."
	end

	xml.status( "code" => eCode ) do
		xml.error( eText )
	end

end