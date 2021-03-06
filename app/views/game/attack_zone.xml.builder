if @result.class == Hash

	# Return success XML.
	# ===================

	xml.status( "code" => 0, "result" => @result[:result], "time" => ( @result[:time].to_f * 1000.0 ).to_i, "controller_called" => "attack_zone" ) do
		for z in @result[:czones]
			if z.user_id != @userid && z.user.jammingcount >= 1
				xml.zone( "x" => z.x, "y" => z.y, "id" => z.user_id, "user" => z.user.name )
			else
				xml.zone( "x" => z.x, "y" => z.y, "id" => z.user_id, "user" => z.user.name,
						  "soldiers" => z.soldiers, "bunker" => z.bunker, "artillery" => z.artillery, "jamming" => z.jamming )
			end
		end

		auser = @result[:auser]
		duser = @result[:duser]


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
						  "viewport_x"		=> auser.viewport_x,		"viewport_y"	=> auser.viewport_y )
		end

		if duser.p2pid_timestamp != nil && ( @result[:time].to_i - auser.p2pid_timestamp.to_i < GameRules::TIMEOUT_P2P_ID )
			xml.userinfo( "id"				=> duser.id,             	"p2pid"			=> duser.p2pid,
						  "name" 			=> duser.name, 				"score" 		=> duser.score,
						  "info" 			=> duser.public_info,		"email"			=> duser.email,
						  "color_r"			=> duser.color_r,			"color_g"   	=> duser.color_g,
						  "color_b"			=> duser.color_b )
		else
			xml.userinfo( "id"				=> duser.id,			  	"name" 			=> duser.name,
						  "score" 			=> duser.score,			    "info" 			=> duser.public_info,
						  "email"			=> duser.email, 			"color_r"		=> duser.color_r,
						  "color_g"   		=> duser.color_g,		    "color_b"		=> duser.color_b )
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
	elsif @result == :database_error || @result == :database_or_constraint_error
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

	xml.status( "code" => eCode, "controller_called" => "attack_zone" ) do
		xml.error( eText )
	end

end