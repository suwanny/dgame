xml.info do
    xml.zone do
        xml.created_at(@zone.created_at)
        xml.id(@zone.id)
        xml.soldiers(@zone.soldiers)
        xml.updated_at(@zone.updated_at)
        xml.user_id(@zone.user_id)
        xml.x(@zone.x)
        xml.y(@zone.y )
    end
    xml.user do
        xml.name(@user.name)
        xml.hashed_password(@user.hashed_password)
        xml.salt(@user.salt)
        xml.email(@user.email)
        xml.turns(@user.turns)
        xml.total_soldiers(@user.total_soldiers)
        xml.total_zones(@user.total_zones)
        xml.score(@user.score)
        xml.last_time_turns_commit(@user.last_time_turns_commit)
        xml.last_time_login(@user.last_time_login)
        xml.public_info(@user.public_info)
        xml.viewport_x(@user.viewport_x)
        xml.viewport_y(@user.viewport_y)
        xml.created_at(@user.created_at)
        xml.updated_at(@user.updated_at)
    end
end