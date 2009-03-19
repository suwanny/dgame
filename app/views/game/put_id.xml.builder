if @result.class != Symbol

	xml.status( "code" => 0, "controller_called" => "put_id" ) do
		auser = @result

		xml.userinfo( "id"				=> auser.id,                "jammingcount"	=> auser.jammingcount,
					  "name" 			=> auser.name, 				"score" 		=> auser.score,
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

	if @result == :invalid_param
		eCode = 90
		eText = "Invalid parameter"
	elsif @result == :user_auth_error
		eCode = 91
		eText = "User auth error"
	elsif @result == :database_error
		eCode = 92
		eText = "Database error"
	end

	xml.status( "code" => eCode, "controller_called" => "put_id" ) do
		xml.error( eText )
	end

end
