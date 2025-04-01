-- List to store authorized overseer users
local authorizedUsers = {}

-- Add extensive debug logging
print("SERVER OVERSEER MODULE LOADING")

-- Function to read the overseerusers.ini file
local function loadAuthorizedUsers()
    print("ATTEMPTING TO LOAD AUTHORIZED USERS")
    authorizedUsers = {}
    -- Try multiple possible locations with better paths
    local paths = {
        "overseerusers.ini",
        "./Lua/overseerusers.ini",
        "./Server/overseerusers.ini",
        "../Lua/overseerusers.ini",
        "../Server/overseerusers.ini"
    }

    local fileReader = nil
    for _, path in ipairs(paths) do
        print("Trying path: " .. path)
        fileReader = getFileReader(path, false)
        if fileReader then
            print("SUCCESS: Found overseerusers.ini at: " .. path)
            break
        end
    end

    if fileReader then
        local line = fileReader:readLine()
        while line do
            line = line:gsub(";.*", ""):gsub("^%s*(.-)%s*,?$", "%1")
            if line ~= "" then
                table.insert(authorizedUsers, line)
                print("Loaded overseer user: " .. line)
            end
            line = fileReader:readLine()
        end
        fileReader:close()
    else
        print("ERROR: Could not find overseerusers.ini file in any location")
    end
end

-- Process client authorization requests
local function onClientCommand(module, command, player, args)
    print("SERVER RECEIVED COMMAND: " .. module .. " - " .. command)

    if module == "OverseerPerk" and command == "RequestAuthorization" then
        local username = player:getUsername()
        print("Processing auth request for: " .. username)

        -- Force authorize DrunkenLee for testing
        if username == "DrunkenLee" then
            print("OVERRIDE: Authorizing " .. username)
            sendServerCommand(player, "OverseerPerk", "SetAuthorized", {isAuthorized = true})
            return
        end

        -- Check against loaded users
        loadAuthorizedUsers() -- Reload to catch updates

        local isAuthorized = false
        for _, user in ipairs(authorizedUsers) do
            if username == user then
                isAuthorized = true
                break
            end
        end

        print("SENDING AUTH RESPONSE: " .. tostring(isAuthorized) .. " to " .. username)
        sendServerCommand(player, "OverseerPerk", "SetAuthorized", {isAuthorized = isAuthorized})
    end
end

-- Initialize with proper event handlers
print("REGISTERING SERVER EVENT HANDLERS")
Events.OnClientCommand.Add(onClientCommand)
Events.OnGameStart.Add(loadAuthorizedUsers)
print("SERVER OVERSEER MODULE LOADED SUCCESSFULLY")