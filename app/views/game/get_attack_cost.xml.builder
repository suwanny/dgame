if @result.is_a?(Numeric)

	# Return success XML.
	# ===================

	xml.status( "code" => 0, "controller_called" => "get_attack_cost" ) do
			xml.attackcost( "cost" => @result )
	end

else

	# Return error XML.
	# =================

	eCode = -1
	eText = "Unknown Error"

	if @result == :user_auth_error
		eCode = 69
		eText = "User authentication error"
	elsif @result == :database_error
		eCode = 70
		eText = "Database error"
	elsif @result == :invalid_params
		eCode = 71
		eText = "Invalid parameters"
	elsif @result == :invalid_target
		eCode = 72
		eText = "Invalid target"
	elsif @result == :cant_attack_zone
		eCode = 73
		eText = "Can't attack zone"
	end

	xml.status( "code" => eCode ) do
		xml.error( eText )
	end

end