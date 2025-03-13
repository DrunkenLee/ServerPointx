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

return GlobalMethods