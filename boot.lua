term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.lightBlue)
print("CraftOS Desktop v1.0")
term.setTextColor(colors.white)
print("Loading system...")
print("")

local ok, err = pcall(function()
    shell.run("system/desktop.lua")
end)

if not ok then
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.red)
    print("FATAL ERROR")
    term.setTextColor(colors.white)
    print(tostring(err))
    print("")
    print("Press any key to restart...")
    os.pullEvent("key")
    os.reboot()
end
