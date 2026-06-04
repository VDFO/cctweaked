local config = {}

config.path = "user/settings.cfg"
config.defaults = {
    theme = "default",
    monitorMode = "auto",
    monitorName = nil,
    textScale = 1.0,
    username = "User",
    networkHost = nil,
}

function config.load()
    if fs.exists(config.path) then
        local file = fs.open(config.path, "r")
        if file then
            local data = file.readAll()
            file.close()
            local parsed = textutils.unserialize(data)
            if parsed then
                for k, v in pairs(config.defaults) do
                    if parsed[k] == nil then
                        parsed[k] = v
                    end
                end
                return parsed
            end
        end
    end
    return config.defaults
end

function config.save(settings)
    local file = fs.open(config.path, "w")
    if file then
        file.write(textutils.serialize(settings))
        file.close()
        return true
    end
    return false
end

return config
