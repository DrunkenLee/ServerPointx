GlobalMethods = GlobalMethods or {}

local playerPoints = {}
local ServerPointsUI = require "ServerPointsUI"

local function OnServerCommand(module, command, arguments)
  if module == "ServerPoints" and command == "get" then
      ServerPointsUI.instance.points = arguments[1]
      return ServerPointsUI.instance.points
      -- print("Received points: " .. tostring(arguments[1])) -- Print the received points
  end
end

function GlobalMethods.addPlayerPoints(username, points)
    sendClientCommand("ServerPoints", "add", { username, points })
    print("Redeemed " .. points .. " [ServerPoints]")
end

function GlobalMethods.takePlayerPoints(username, points)
    local takenPoints = 0 - points
    sendClientCommand("ServerPoints", "add", { username, takenPoints })
    print("Taken " .. points .. " [ServerPoints]")
end

function GlobalMethods.getPlayerPoints(username)
    Events.OnServerCommand.Add(OnServerCommand)
    sendClientCommand("ServerPoints", "get", { username })
    return ServerPointsUI.instance.points or 0
end

function GlobalMethods.depositPoints(username, amount)
    if not username or not amount or amount <= 0 then
        print("Invalid deposit request")
        return false
    end

    sendClientCommand("ServerPoints", "deposit", { username, amount })
    print("Deposit request sent: " .. amount .. " points for " .. username)
    return true
end

function GlobalMethods.depositRaidPoints(username, amount)
    if not username or not amount or amount <= 0 then
        print("Invalid raid deposit request")
        return false
    end

    sendClientCommand("ServerRaidPoints", "deposit", { username, amount })
    print("Raid deposit request sent: " .. amount .. " raid points for " .. username)
    return true
end

-- Handle deposit response from server
local function onServerDepositResponse(module, command, arguments)
    if module == "ServerPoints" and command == "depositResult" then
        local player = getPlayer()
        if arguments.success then
            player:Say("Successfully deposited " .. arguments.amount .. " points")
        else
            player:Say("Deposit failed: " .. (arguments.message or "Unknown error"))
        end
    end
end

local function onServerRaidDepositResponse(module, command, arguments)
    if module == "ServerRaidPoints" and command == "depositResult" then
        local player = getPlayer()
        if arguments.success then
            player:Say("Successfully deposited " .. arguments.amount .. " raid points")
        else
            player:Say("Raid deposit failed: " .. (arguments.message or "Unknown error"))
        end
    end
end

-- Register the response handler
Events.OnServerCommand.Add(onServerDepositResponse)
Events.OnServerCommand.Add(onServerRaidDepositResponse)

function GlobalMethods.withdrawPoints(username)
    if not username then
        print("Invalid withdrawal request")
        return false
    end

    sendClientCommand("ServerPoints", "withdraw", { username })
    print("Withdrawal request sent for " .. username)
    return true
end

function GlobalMethods.withdrawRaidPoints(username)
    if not username then
        print("Invalid raid withdrawal request")
        return false
    end

    sendClientCommand("ServerRaidPoints", "withdraw", { username })
    print("Raid withdrawal request sent for " .. username)
    return true
end

local function onServerWithdrawResponse(module, command, arguments)
    if module == "ServerPoints" and command == "withdrawResult" then
        local player = getPlayer()
        if arguments.success then
            player:Say("Successfully withdrew " .. arguments.amount .. " points")
        else
            player:Say("Withdrawal failed: " .. (arguments.message or "Unknown error"))
        end
    end
end

local function onServerRaidWithdrawResponse(module, command, arguments)
    if module == "ServerRaidPoints" and command == "withdrawResult" then
        local player = getPlayer()
        if arguments.success then
            player:Say("Successfully withdrew " .. arguments.amount .. " raid points")
        else
            player:Say("Raid withdrawal failed: " .. (arguments.message or "Unknown error"))
        end
    end
end

local function onServerAddPoints(module, command, arguments)
    if module == "ServerPoints" and command == "addPoints" then
        local amount = arguments[1]
        if amount then
            -- Add points to player's balance (this should trigger your existing points system)
            print("Adding " .. amount .. " points from withdrawal")
            GlobalMethods.addPlayerPoints(getPlayer():getUsername(), amount)
        end
    elseif module == "ServerRaidPoints" and command == "addPoints" then
        local amount = arguments[1]
        if amount then
            -- Add raid points to player's balance

            print("Adding " .. amount .. " raid points from withdrawal")
            local index = CharacterManager.instance:indexOf("shop01")
            if index then
                CharacterManager.instance.items[index]:increaseStat("skinPoint", amount)
            else
                print("Karakter shop01 tidak ditemukan!")
            end

        end
    end
end

Events.OnServerCommand.Add(onServerWithdrawResponse)
Events.OnServerCommand.Add(onServerRaidWithdrawResponse)
Events.OnServerCommand.Add(onServerAddPoints)

return GlobalMethods