if @result.class != Symbol

	# Return success XML.
	# ===================

	xml.status( "code" => 0, "controller_called" => "get_user_info" ) do
		auser = @result

		if @userid == auser.id
			if auser.p2pid_timestamp != nil && ( @result[:time].to_i - auser.p2pid_timestamp.to_i < GameRules::TIMEOUT_P2P_ID )
				xml.userinfo( "id"				=> auser.id,                "jammingcount"	=> auser.jammingcount,
							  "name" 			=> auser.name, 				"score" 		=> auser.score,
							  "info" 			=> auser.public_info,		"email"			=> auser.email,
							  "color_r"			=> auser.color_r,			"color_g"   	=> auser.color_g,
							  "color_b"			=> auser.color_b,			"turns"			=> auser.turns,
							  "total_soldiers"	=> auser.total_soldiers,	"total_zones"	=> auser.total_zones,
							  "viewport_x"		=> auser.viewport_x,		"viewport_y"	=> auser.viewport_y,
							  "p2pid"			=> auser.p2pid )
			else
				xml.userinfo( "id"				=> auser.id,                "jammingcount"	=> auser.jammingcount,
							  "name" 			=> auser.name, 				"score" 		=> auser.score,
							  "info" 			=> auser.public_info,		"email"			=> auser.email,
							  "color_r"			=> auser.color_r,			"color_g"   	=> auser.color_g,
							  "color_b"			=> auser.color_b,			"turns"			=> auser.turns,
							  "total_soldiers"	=> auser.total_soldiers,	"total_zones"	=> auser.total_zones,
							  "viewport_x"		=> auser.viewport_x,		"viewport_y"	=> auser.viewport_y, "a" => auser.p2pid_timestamp.to_i, "b" => @result[:time].to_i, "c" =>  GameRules::TIMEOUT_P2P_ID )
			end
		else
			if auser.p2pid_timestamp != nil && ( @result[:time].to_i - auser.p2pid_timestamp.to_i < GameRules::TIMEOUT_P2P_ID )
				xml.userinfo( "id"				=> auser.id,           		"p2pid"			=> auser.p2pid,
							  "name" 			=> auser.name, 				"score" 		=> auser.score,
							  "info" 			=> auser.public_info,		"email"			=> auser.email,
							  "color_r"			=> auser.color_r,			"color_g"   	=> auser.color_g,
							  "color_b"			=> auser.color_b )
			else
				xml.userinfo( "id"				=> auser.id,           		"name" 			=> auser.name,
							  "score" 			=> auser.score,			    "info" 			=> auser.public_info,
							  "email"			=> auser.email, 		    "color_r"		=> auser.color_r,
							  "color_g"   		=> auser.color_g,			"color_b"		=> auser.color_b )
			end
		end
	end

else

	# Return error XML.
	# =================

	eCode = -1
	eText = "Unknown Error"

	if @result == :invalid_param
		eCode = 64
		eText = "Invalid parameter"
	elsif @result == :no_user
		eCode = 65
		eText = "No such user"
	end

	xml.status( "code" => eCode, "controller_called" => "get_user_info" ) do
		xml.error( eText )
	end

end