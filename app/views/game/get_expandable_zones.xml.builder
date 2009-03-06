if @error.nil?

	# Return success XML.
	# ===================

	xml.status( "code" => 0, "controller_called" => "get_expandable_zones" ) do
		for r in @result
			xml.zone( "x" => r.x, "y" => r.y )
		end
	end

else

	# Return error XML.
	# =================

	eCode = -1
	eText = "Unknown Error"
	
	if @error == :user_not_found
		eCode = 1
		eText = "User not found/Authentication error"
	elsif @error == :database_error
		eCode = 2
		eText = "Database error"
	end

	xml.status( "code" => eCode ) do
		xml.error( eText )
	end

end