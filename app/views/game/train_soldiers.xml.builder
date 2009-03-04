if @result.class == Hash

	# Return success XML.
	# ===================

	z = @result[:czone]

	xml.status( "code" => 0, "time" => ( @result[:time].to_f * 1000.0 ).to_i ) do
		xml.soldiers( "trained" => @result[:trained], 	"newcountatzone" => @result[:newcountatzone],
					  "newtotal" => @result[:newtotal],	"nextup" => @result[:nextup] )
		xml.zone( "x" => z.x, "y" => z.y, "id" => z.user_id, "user" => z.user.name,
			      "soldiers" => z.soldiers, "bunker" => z.bunker, "artillery" => z.artillery, "jamming" => z.jamming )
	end

else

	# Return error XML.
	# =================

	eCode = -1
	eText = "Unknown Error"

	if @result == :user_auth_error
		eCode = 17
		eText = "User authentication error"
	elsif @result == :database_error
		eCode = 18
		eText = "Database error or Constraint error"
	elsif @result == :invalid_parameter
		eCode = 19
		eText = "Invalid Parameter"
	elsif @result == :not_enough_turns
		eCode = 20
		eText = "Not enough turns"
	elsif @result == :no_such_zone
		eCode = 34
		eText = "Zone at target is empty."
	elsif @result == :user_zone_mismatch
		eCode = 35
		eText = "Zone is not owned by user."
	end

	xml.status( "code" => eCode ) do
		xml.error( eText )
	end

end