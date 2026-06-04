local network = {}

network.open = false
network.hostname = nil

function network.init()
    local modems = peripheral.find("modem", rednet.open)
    if modems then
        network.open = true
        return true
    end
    return false
end

function network.close()
    rednet.close()
    network.open = false
end

function network.host(protocol, hostname)
    if not network.open then network.init() end
    if network.open then
        rednet.host(protocol, hostname)
        network.hostname = hostname
        return true
    end
    return false
end

function network.unhost(protocol)
    rednet.unhost(protocol)
end

function network.send(id, message, protocol)
    if not network.open then return false end
    return rednet.send(id, message, protocol)
end

function network.broadcast(message, protocol)
    if not network.open then return false end
    rednet.broadcast(message, protocol)
    return true
end

function network.receive(protocol, timeout)
    if not network.open then return nil end
    return rednet.receive(protocol, timeout)
end

function network.lookup(protocol, hostname, timeout)
    if not network.open then return nil end
    return rednet.lookup(protocol, hostname, timeout)
end

function network.isOpen()
    return network.open
end

return network
