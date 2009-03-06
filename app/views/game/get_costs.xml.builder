
xml.status( "code" => 0, "controller_called" => "get_costs" ) do
	xml.costs( "artillery" => @result[:artillery], "bunker" => @result[:bunker], "jamming" => @result[:jamming] )
end