
xml.status( "code" => 0 ) do
	xml.costs( "artillery" => @result[:artillery], "bunker" => @result[:bunker], "jamming" => @result[:jamming] )
end