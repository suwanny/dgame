if @result.class != Symbol

	# Return success XML.
	# ===================

	xml.status( "code" => 0, "controller_called" => "get_zone_data" ) do

		for z in @result[:zones]
			if z.user_id != @userid && z.user.jammingcount >= 1
				xml.zone( "x" => z.x, "y" => z.y, "id" => z.user_id )
			else
				xml.zone( "x" => z.x, "y" => z.y, "id" => z.user_id,
						  "soldiers" => z.soldiers, "bunker" => z.bunker, "artillery" => z.artillery, "jamming" => z.jamming )
			end
		end

		for a in @result[:users]
			user = a[1]

			if user != nil
				if @userid == user.id
					if user.p2pid_timestamp != nil && ( Time.now.to_i - user.p2pid_timestamp.to_i < GameRules::TIMEOUT_P2P_ID )
						xml.userinfo( "id"				=> user.id,                "jammingcount"	=> user.jammingcount,
									  "name" 			=> user.name, 				"score" 		=> user.score,
									  "info" 			=> user.public_info,		"email"			=> user.email,
									  "color_r"			=> user.color_r,			"color_g"   	=> user.color_g,
									  "color_b"			=> user.color_b,			"turns"			=> user.turns,
									  "total_soldiers"	=> user.total_soldiers,		"total_zones"	=> user.total_zones,
									  "viewport_x"		=> user.viewport_x,			"viewport_y"	=> user.viewport_y,
									  "p2pid"			=> user.p2pid )
					else
						xml.userinfo( "id"				=> user.id,                "jammingcount"	=> user.jammingcount,
									  "name" 			=> user.name, 				"score" 		=> user.score,
									  "info" 			=> user.public_info,		"email"			=> user.email,
									  "color_r"			=> user.color_r,			"color_g"   	=> user.color_g,
									  "color_b"			=> user.color_b,			"turns"			=> user.turns,
									  "total_soldiers"	=> user.total_soldiers,		"total_zones"	=> user.total_zones,
									  "viewport_x"		=> user.viewport_x,			"viewport_y"	=> user.viewport_y )
					end
				else
					if user.p2pid_timestamp != nil && ( Time.now.to_i - user.p2pid_timestamp.to_i < GameRules::TIMEOUT_P2P_ID )
						xml.userinfo( "id"				=> user.id,           		"p2pid"			=> user.p2pid,
									  "name" 			=> user.name, 				"score" 		=> user.score,
									  "info" 			=> user.public_info,		"email"			=> user.email,
									  "color_r"			=> user.color_r,			"color_g"   	=> user.color_g,
									  "color_b"			=> user.color_b )
					else
						xml.userinfo( "id"				=> user.id,           		"name" 			=> user.name,
									  "score" 			=> user.score,			    "info" 			=> user.public_info,
									  "email"			=> user.email, 		    	"color_r"		=> user.color_r,
									  "color_g"   		=> user.color_g,			"color_b"		=> user.color_b )
					end
				end
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

	xml.status( "code" => eCode, "controller_called" => "get_zone_data" ) do
		xml.error( eText )
	end

end