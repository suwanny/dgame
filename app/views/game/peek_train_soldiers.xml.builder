if @result.is_a?(Numeric)

	# Return success XML.
	# ===================

	xml.status( "code" => 0 ) do
		xml.soldiers( "count" => @result )
	end

else

	# Return error XML.
	# =================

	eCode = -1
	eText = "Unknown Error"

	if @result == :invalid_param
		eCode = 16
		eText = "Invalid Parameter / User not found"
	end

	xml.status( "code" => eCode ) do
		xml.error( eText )
	end

end