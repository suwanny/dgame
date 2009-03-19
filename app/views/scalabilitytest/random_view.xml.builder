	# ===================

	xml.status( "code" => 0, "controller_called" => "get_zone_data" ) do

        if GameController::USE_MEMCACHED
            if @zonedata_str != :wrong_parameter
                xml.zone_group("content" => @zonedata_str)
            end
        else
            for z in @zonedata
                    xml.zone( "x" => z.x, "y" => z.y, "id" => z.user_id,
                              "soldiers" => z.soldiers, "bunker" => z.bunker, "artillery" => z.artillery, "jamming" => z.jamming )
            end
        end

end