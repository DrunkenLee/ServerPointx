require "ServerPointsShared"

local ServerDepositPoints = {}

local function getDepositDirectory()
    local saveDir = "Deposits"
    if isServer() then
        saveDir = saveDir
    else
        saveDir = "Deposits"
    end
    return saveDir
end

local function writeDepositToFile(username, amount)
    local filePath = getDepositDirectory() .. "/" .. username .. "_deposits.ini"

    -- Create timestamp
    local timeStamp = os.date("%Y-%m-%d %H:%M:%S")

    -- Prepare data to write
    local fileWriter = getFileWriter(filePath, true, true) -- append mode
    if fileWriter then
        fileWriter:write("[Deposit]\n")
        fileWriter:write("Time=" .. timeStamp .. "\n")
        fileWriter:write("Amount=" .. tostring(amount) .. "\n")
        fileWriter:close()
        return true
    end

    print("ERROR: Failed to write to deposit file: " .. filePath)
    return false
end

local function onClientDepositRequest(module, command, player, args)
    if module ~= "ServerPoints" or command ~= "deposit" then return end
    print("DEBUG: onClientDepositRequest called")

    local username = args[1]
    local amount = tonumber(args[2])
    local result = { success = false }

    -- Validate request
    if not username or not amount or amount <= 0 then
        result.message = "Invalid deposit request"
        sendServerCommand(player, "ServerPoints", "depositResult", result)
        return
    end

    -- Check if this is the right player making the request
    if username ~= player:getUsername() then
        result.message = "You can only deposit your own points"
        sendServerCommand(player, "ServerPoints", "depositResult", result)
        return
    end

    -- Just record the deposit without checking points balance
    if writeDepositToFile(username, amount) then
        -- Success
        result.success = true
        result.amount = amount

        -- Send a server command to deduct points on the client side
        sendServerCommand(player, "ServerPoints", "deductPoints", { amount })
    else
        result.message = "Failed to write deposit to file"
    end

    sendServerCommand(player, "ServerPoints", "depositResult", result)
end

Events.OnClientCommand.Add(onClientDepositRequest)

return ServerDepositPoints