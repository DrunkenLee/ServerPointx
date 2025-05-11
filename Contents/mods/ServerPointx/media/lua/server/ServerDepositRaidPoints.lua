require "ServerPointsShared"

local ServerDepositRaidPoints = {}

local function getRaidDepositDirectory()
    local saveDir = "RaidDeposits"
    if isServer() then
        saveDir = saveDir
    else
        saveDir = "RaidDeposits"
    end
    return saveDir
end

local function writeRaidDepositToFile(username, amount)
    local filePath = getRaidDepositDirectory() .. "/" .. username .. "_raiddeposits.ini"

    local timeStamp = os.date("%Y-%m-%d %H:%M:%S")

    local fileWriter = getFileWriter(filePath, true, true)
    if fileWriter then
        fileWriter:write("[RaidDeposit]\n")
        fileWriter:write("Time=" .. timeStamp .. "\n")
        fileWriter:write("Amount=" .. tostring(amount) .. "\n")
        fileWriter:close()
        return true
    end

    print("ERROR: Failed to write to raid deposit file: " .. filePath)
    return false
end

local function onClientRaidDepositRequest(module, command, player, args)
    if module ~= "ServerRaidPoints" or command ~= "deposit" then return end
    print("DEBUG: onClientRaidDepositRequest (RaidPoints) called")

    local username = args[1]
    local amount = tonumber(args[2])
    local result = { success = false }

    if not username or not amount or amount <= 0 then
        result.message = "Invalid raid deposit request"
        sendServerCommand(player, "ServerRaidPoints", "depositResult", result)
        return
    end

    if username ~= player:getUsername() then
        result.message = "You can only deposit your own raid points"
        sendServerCommand(player, "ServerRaidPoints", "depositResult", result)
        return
    end

    if writeRaidDepositToFile(username, amount) then
        -- Success
        result.success = true
        result.amount = amount

        sendServerCommand(player, "ServerRaidPoints", "deductPoints", { amount })
    else
        result.message = "Failed to write raid deposit to file"
    end

    sendServerCommand(player, "ServerRaidPoints", "depositResult", result)
end

Events.OnClientCommand.Add(onClientRaidDepositRequest)

return ServerDepositRaidPoints