local BASE_URL = "https://raw.githubusercontent.com/VDFO/cctweaked/main"

local files = {
    {path = "boot.lua", url = BASE_URL .. "/boot.lua"},
    {path = "startup.lua", url = BASE_URL .. "/startup.lua"},
    
    {path = "system/kernel.lua", url = BASE_URL .. "/system/kernel.lua"},
    {path = "system/desktop.lua", url = BASE_URL .. "/system/desktop.lua"},
    {path = "system/events.lua", url = BASE_URL .. "/system/events.lua"},
    {path = "system/theme.lua", url = BASE_URL .. "/system/theme.lua"},
    {path = "system/config.lua", url = BASE_URL .. "/system/config.lua"},
    
    {path = "lib/draw.lua", url = BASE_URL .. "/lib/draw.lua"},
    {path = "lib/widget.lua", url = BASE_URL .. "/lib/widget.lua"},
    {path = "lib/modal.lua", url = BASE_URL .. "/lib/modal.lua"},
    {path = "lib/filesystem.lua", url = BASE_URL .. "/lib/filesystem.lua"},
    {path = "lib/network.lua", url = BASE_URL .. "/lib/network.lua"},
    
    {path = "programs/terminal.lua", url = BASE_URL .. "/programs/terminal.lua"},
    {path = "programs/filemanager.lua", url = BASE_URL .. "/programs/filemanager.lua"},
    {path = "programs/editor.lua", url = BASE_URL .. "/programs/editor.lua"},
    {path = "programs/settings.lua", url = BASE_URL .. "/programs/settings.lua"},
    {path = "programs/taskmanager.lua", url = BASE_URL .. "/programs/taskmanager.lua"},
    {path = "programs/paint.lua", url = BASE_URL .. "/programs/paint.lua"},
    {path = "programs/redstone.lua", url = BASE_URL .. "/programs/redstone.lua"},
    {path = "programs/clock.lua", url = BASE_URL .. "/programs/clock.lua"},
    {path = "programs/calculator.lua", url = BASE_URL .. "/programs/calculator.lua"},
    {path = "programs/chat.lua", url = BASE_URL .. "/programs/chat.lua"},
    {path = "programs/chess.lua", url = BASE_URL .. "/programs/chess.lua"},
    {path = "programs/monitor.lua", url = BASE_URL .. "/programs/monitor.lua"},
    
    {path = "assets/wallpaper.nfp", url = BASE_URL .. "/assets/wallpaper.nfp"},
    {path = "user/settings.cfg", url = BASE_URL .. "/user/settings.cfg"},
}

local directories = {
    "system",
    "lib",
    "programs",
    "assets",
    "user",
    "user/documents",
}

local function printHeader(text)
    term.setTextColor(colors.lightBlue)
    print(text)
    term.setTextColor(colors.white)
end

local function printSuccess(text)
    term.setTextColor(colors.lime)
    print(text)
    term.setTextColor(colors.white)
end

local function printError(text)
    term.setTextColor(colors.red)
    print(text)
    term.setTextColor(colors.white)
end

local function printWarning(text)
    term.setTextColor(colors.yellow)
    print(text)
    term.setTextColor(colors.white)
end

term.clear()
term.setCursorPos(1, 1)

printHeader("=================================")
printHeader("   CraftOS Desktop Installer")
printHeader("=================================")
print("")

print("This will install CraftOS Desktop on your computer.")
print("")
printWarning("WARNING: This will overwrite existing files!")
print("")
write("Continue? (y/n): ")
local answer = read()

if answer:lower() ~= "y" then
    printError("Installation cancelled.")
    return
end

print("")
printHeader("Creating directories...")

for _, dir in ipairs(directories) do
    if not fs.isDir(dir) then
        fs.makeDir(dir)
        printSuccess("  Created: " .. dir)
    else
        print("  Exists: " .. dir)
    end
end

print("")
printHeader("Downloading files...")
print("")

local successCount = 0
local failCount = 0

for i, file in ipairs(files) do
    write(string.format("[%2d/%2d] %s... ", i, #files, file.path))
    
    local ok, err = pcall(function()
        shell.run("wget", file.url, file.path)
    end)
    
    if ok and fs.exists(file.path) then
        printSuccess("OK")
        successCount = successCount + 1
    else
        printError("FAILED")
        if err then
            printError("  Error: " .. tostring(err))
        end
        failCount = failCount + 1
    end
    
    sleep(0.1)
end

print("")
printHeader("=================================")
printHeader("   Installation Complete!")
printHeader("=================================")
print("")
printSuccess("Successfully installed: " .. successCount .. " files")

if failCount > 0 then
    printError("Failed to install: " .. failCount .. " files")
    print("")
    printWarning("Some files failed to download.")
    print("Check your internet connection and try again.")
else
    print("")
    printSuccess("All files installed successfully!")
    print("")
    print("Rebooting in 3 seconds...")
    sleep(3)
    os.reboot()
end
