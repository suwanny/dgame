if @result.class == Hash

	# Return success XML.
	# ===================

	xml.status( "code" => 0, "controller_called" => "set_viewport_data" ) do
		xml.result( true )
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
		eCode = 66
		eText = "User authentication error"
	elsif @result == :database_error
		eCode = 67
		eText = "Database error"
	elsif @result == :invalid_parameters
		eCode = 68
		eText = "Invalid parameters."
	end

	xml.status( "code" => eCode ) do
		xml.error( eText )
	end

end