if @result.class != Symbol

	xml.status( "code" => 0, "controller_called" => "get_id" ) do
		auser = @result

		xml.userinfo( "p2pid" => auser.p2pid, "timestamp" => auser.p2pid_timestamp )
	end

else

	# Return error XML.
	# =================

	eCode = -1
	eText = "Unknown Error"

	if @result == :invalid_parameters
		eCode = 93
		eText = "Invalid parameters"
	elsif @result == :user_auth_error
		eCode = 94
		eText = "User auth error"
	elsif @result == :database_error
		eCode = 95
		eText = "Database error"
	end

	xml.status( "code" => eCode, "controller_called" => "get_id" ) do
		xml.error( eText )
	end

end
