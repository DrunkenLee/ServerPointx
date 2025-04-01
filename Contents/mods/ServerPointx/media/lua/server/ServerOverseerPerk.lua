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
        "../Server/overseerusers.ini",
        "C:/Users/Michael/Zomboid/Lua/overseerusers.ini",
        "C:/Users/Michael/Zomboid/Server/overseerusers.ini"
    }

    local fileReader = nil
    local successPath = nil

    for _, path in ipairs(paths) do
        print("Trying path: " .. path)
        fileReader = getFileReader(path, false)
        if fileReader then
            print("SUCCESS: Found overseerusers.ini at: " .. path)
            successPath = path
            break
        end
    end

    if fileReader then
        local line = fileReader:readLine()
        while line do
            -- Remove comments, trim spaces and commas
            line = line:gsub(";.*", ""):gsub("^%s*(.-)%s*,?$", "%1")
            if line ~= "" then
                table.insert(authorizedUsers, line)
                print("Loaded overseer user: " .. line)
            end
            line = fileReader:readLine()
        end
        fileReader:close()

        print("Successfully loaded " .. #authorizedUsers .. " authorized users from " .. successPath)
    else
        print("ERROR: Could not find overseerusers.ini file in any location")
        -- Add a fallback for testing
        table.insert(authorizedUsers, "DrunkenLee")
        print("FALLBACK: Added DrunkenLee to authorized users for testing")
    end
end

-- Process client authorization requests
local function onClientCommand(module, command, player, args)
    print("SERVER RECEIVED COMMAND: " .. module .. " - " .. command .. " from " .. player:getUsername())

    if module == "OverseerPerk" then
        if command == "RequestAuthorization" then
            local username = player:getUsername()
            print("Processing auth request for: " .. username)

            -- For testing/development - force authorize specific users
            if username == "DrunkenLee" then
                print("DEVELOPER OVERRIDE: Authorizing " .. username)
                sendServerCommand(player, "OverseerPerk", "SetAuthorized", {isAuthorized = true})
                return
            end

            -- Check against loaded users
            loadAuthorizedUsers() -- Reload to catch updates

            -- Debug: print all loaded users
            print("CHECKING AGAINST AUTHORIZED USERS:")
            for i, user in ipairs(authorizedUsers) do
                print(i .. ": '" .. user .. "'")
            end

            local isAuthorized = false
            for _, user in ipairs(authorizedUsers) do
                print("Comparing '" .. username .. "' with '" .. user .. "'")
                if username == user then
                    isAuthorized = true
                    print("MATCH FOUND - User is authorized")
                    break
                end
            end

            print("SENDING AUTH RESPONSE: " .. tostring(isAuthorized) .. " to " .. username)
            sendServerCommand(player, "OverseerPerk", "SetAuthorized", {isAuthorized = isAuthorized})
        elseif command == "TestConnection" then
            print("TEST CONNECTION REQUEST RECEIVED FROM: " .. player:getUsername())
            -- Send a response back
            sendServerCommand(player, "OverseerPerk", "TestResponse", {message = "Connection working!"})
        end
    end
end

-- Initialize with proper event handlers
print("REGISTERING SERVER EVENT HANDLERS")
Events.OnClientCommand.Add(onClientCommand)
Events.OnGameStart.Add(loadAuthorizedUsers)
print("SERVER OVERSEER MODULE LOADED SUCCESSFULLY")