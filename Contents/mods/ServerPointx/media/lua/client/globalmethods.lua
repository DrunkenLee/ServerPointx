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

-- Register the response handler
Events.OnServerCommand.Add(onServerDepositResponse)

return GlobalMethods