if @result.is_a?(Numeric)

	# Return success XML.
	# ===================

	xml.status( "code" => 0, "controller_called" => "get_expand_cost" ) do
			xml.expandcost( "cost" => @result )
	end

else

	# Return error XML.
	# =================

	eCode = -1
	eText = "Unknown Error"

	if @result == :invalid_params
		eCode = 74
		eText = "Invalid parameters"
	end

	xml.status( "code" => eCode ) do
		xml.error( eText )
	end

end