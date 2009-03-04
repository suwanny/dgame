if @result == TrueClass

	# Return success XML.
	# ===================

	xml.status( "code" => 0 ) do
		xml.result( true )
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