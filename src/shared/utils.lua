function validateBlipBuilder(builder)
    if (not (builder.sprite)) then
        return (false)
    end
    if (not (builder.name)) then
        return (false)
    end
    if (not (builder.color)) then
        return (false)
    end

    return (true)
end