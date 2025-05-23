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

local function readDepositsFromFile(username)
    local filePath = getDepositDirectory() .. "/" .. username .. "_deposits.ini"

    -- Check if file exists
    local file = getFileReader(filePath, false)
    if not file then
        print("INFO: No deposits file found for " .. username)
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

local function onClientWithdrawRequest(module, command, player, args)
    if module ~= "ServerPoints" or command ~= "withdraw" then return end
    print("DEBUG: onClientWithdrawRequest called")

    local username = args[1]
    local result = { success = false }

    -- Validate request
    if not username then
        result.message = "Invalid withdrawal request"
        sendServerCommand(player, "ServerPoints", "withdrawResult", result)
        return
    end

    -- Check if this is the right player making the request
    if username ~= player:getUsername() then
        result.message = "You can only withdraw your own points"
        sendServerCommand(player, "ServerPoints", "withdrawResult", result)
        return
    end

    -- Get total deposits
    local totalDeposits = readDepositsFromFile(username)

    if totalDeposits <= 0 then
        result.message = "No deposits found to withdraw"
        sendServerCommand(player, "ServerPoints", "withdrawResult", result)
        return
    end

    -- Get file paths
    local filePath = getDepositDirectory() .. "/" .. username .. "_deposits.ini"
    local newFilePath = getDepositDirectory() .. "/" .. username .. "_deposits_withdrawed.ini"

    -- Move file content and create the withdrawed file
    if moveFileContent(filePath, newFilePath) then
        -- Success
        result.success = true
        result.amount = totalDeposits

        -- Tell client to add the points
        sendServerCommand(player, "ServerPoints", "addPoints", { totalDeposits })
    else
        result.message = "Failed to process withdrawal"
    end

    sendServerCommand(player, "ServerPoints", "withdrawResult", result)
end

Events.OnClientCommand.Add(onClientDepositRequest)

Events.OnClientCommand.Add(onClientWithdrawRequest)

return ServerDepositPoints