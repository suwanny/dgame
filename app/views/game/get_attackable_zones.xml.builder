if @result.class == Array

	# Return success XML.
	# ===================

	xml.status( "code" => 0, "controller_called" => "get_attackable_zones" ) do
		for z in @result
			xml.zone( "x" => z.x, "y" => z.y  )
		end
	end

else

	# Return error XML.
	# =================

	eCode = -1
	eText = "Unknown Error"

	if @result == :user_not_found
		eCode = 14
		eText = "User not found"
	elsif @result == :database_error
		eCode = 15
		eText = "Database error"
	end

	xml.status( "code" => eCode ) do
		xml.error( eText )
	end

end