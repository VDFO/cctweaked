local filesystem = {}

function filesystem.readFile(path)
    if not fs.exists(path) then return nil end
    local file = fs.open(path, "r")
    if not file then return nil end
    local content = file.readAll()
    file.close()
    return content
end

function filesystem.writeFile(path, content)
    local file = fs.open(path, "w")
    if not file then return false end
    file.write(content)
    file.close()
    return true
end

function filesystem.readLines(path)
    local content = filesystem.readFile(path)
    if not content then return {} end
    local lines = {}
    for line in content:gmatch("[^\n]*") do
        table.insert(lines, line)
    end
    return lines
end

function filesystem.writeLines(path, lines)
    return filesystem.writeFile(path, table.concat(lines, "\n"))
end

function filesystem.isDirectory(path)
    return fs.isDir(path)
end

function filesystem.list(path)
    if not fs.isDir(path) then return {} end
    return fs.list(path)
end

function filesystem.copy(src, dst)
    if fs.exists(src) then
        fs.copy(src, dst)
        return true
    end
    return false
end

function filesystem.move(src, dst)
    if fs.exists(src) then
        fs.move(src, dst)
        return true
    end
    return false
end

function filesystem.delete(path)
    if fs.exists(path) then
        fs.delete(path)
        return true
    end
    return false
end

function filesystem.getSize(path)
    if fs.exists(path) then
        return fs.getSize(path)
    end
    return 0
end

function filesystem.getName(path)
    return fs.getName(path)
end

function filesystem.getDir(path)
    return fs.getDir(path)
end

function filesystem.combine(path, name)
    return fs.combine(path, name)
end

return filesystem
