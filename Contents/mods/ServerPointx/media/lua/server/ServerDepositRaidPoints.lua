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

local function readRaidDepositsFromFile(username)
    local filePath = getRaidDepositDirectory() .. "/" .. username .. "_raiddeposits.ini"

    -- Check if file exists
    local file = getFileReader(filePath, false)
    if not file then
        print("INFO: No raid deposits file found for " .. username)
        return 0
    end

    -- Read the file to get total deposit amount
    local totalAmount = 0
    local line = file:readLine()
    while line ~= nil do
        if line:find("Amount=") then
            local amount = tonumber(line:match("Amount=(.*)"))
            if amount then totalAmount = totalAmount + amount end
        end
        line = file:readLine()
    end
    file:close()

    return totalAmount
end

local function moveFileContent(oldPath, newPath)
    local oldFile = getFileReader(oldPath, false)
    if not oldFile then return false end

    local newFile = getFileWriter(newPath, true, false)
    if not newFile then
        oldFile:close()
        return false
    end

    local line = oldFile:readLine()
    while line ~= nil do
        newFile:write(line .. "\n")
        line = oldFile:readLine()
    end

    oldFile:close()
    newFile:close()

    local eraseFile = getFileWriter(oldPath, false, false)
    if eraseFile then
        eraseFile:write("")
        eraseFile:close()
    end

    return true
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
        result.success = true
        result.amount = amount

        sendServerCommand(player, "ServerRaidPoints", "deductPoints", { amount })
    else
        result.message = "Failed to write raid deposit to file"
    end

    sendServerCommand(player, "ServerRaidPoints", "depositResult", result)
end


local function onClientRaidWithdrawRequest(module, command, player, args)
    if module ~= "ServerRaidPoints" or command ~= "withdraw" then return end
    print("DEBUG: onClientRaidWithdrawRequest called")

    local username = args[1]
    local result = { success = false }

    if not username then
        result.message = "Invalid raid withdrawal request"
        sendServerCommand(player, "ServerRaidPoints", "withdrawResult", result)
        return
    end

    if username ~= player:getUsername() then
        result.message = "You can only withdraw your own raid points"
        sendServerCommand(player, "ServerRaidPoints", "withdrawResult", result)
        return
    end

    local totalDeposits = readRaidDepositsFromFile(username)

    if totalDeposits <= 0 then
        result.message = "No raid deposits found to withdraw"
        sendServerCommand(player, "ServerRaidPoints", "withdrawResult", result)
        return
    end

    local filePath = getRaidDepositDirectory() .. "/" .. username .. "_raiddeposits.ini"

    local newFilePath = getRaidDepositDirectory() .. "/" .. username .. "_raiddeposits_withdrawed.ini"

    if moveFileContent(filePath, newFilePath) then
        result.success = true
        result.amount = totalDeposits

        sendServerCommand(player, "ServerRaidPoints", "addPoints", { totalDeposits })
    else
        result.message = "Failed to process raid withdrawal"
    end

    sendServerCommand(player, "ServerRaidPoints", "withdrawResult", result)
end

Events.OnClientCommand.Add(onClientRaidDepositRequest)

Events.OnClientCommand.Add(onClientRaidWithdrawRequest)

return ServerDepositRaidPoints