if @result.type == User.type

	# Return success XML.
	# ===================

	xml.status( "code" => 0, "controller_called" => "get_user_info" ) do
		if @userid == @result.id
			xml.userinfo( "name" 			=> @result.name, 			"score" 		=> @result.score,
						  "info" 			=> @result.public_info,		"email"			=> @result.email,
						  "color_r"			=> @result.color_r,			"color_g"   	=> @result.color_g,
					      "color_b"			=> @result.color_b,			"turns"			=> @result.turns,
				 	      "total_soldiers"	=> @result.total_soldiers,	"total_zones"	=> @result.total_zones,
						  "viewport_x"		=> @result.viewport_x,		"viewport_y"	=> @result.viewport_y )  	  
		else
			xml.userinfo( "name" 			=> @result.name, 			"score" 		=> @result.score,
						  "info" 			=> @result.public_info,		"email"			=> @result.email,
						  "color_r"			=> @result.color_r,			"color_g"   	=> @result.color_g,
					      "color_b"			=> @result.color_b )
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

	xml.status( "code" => eCode ) do
		xml.error( eText )
	end

end