
function Recipe.OnCreate.RedeemPoints(items, result, player)
  local points = items:get(0):getModData().serverPoints or 0
  sendClientCommand("ServerPoints", "add", { player:getUsername(), points })
  player:Say("Redeemed " .. points .. " " .. SandboxVars.ServerPoints.PointsName)
end

-- if not isServer() then return end

local serverPointsData
local listings

local function logServerPointsData()
  for username, points in pairs(serverPointsData) do
      print("Username: " .. username .. ", Points: " .. points)
  end
end

local function PointsTick()
  local players = getOnlinePlayers()
  for i = 0, players:size() - 1 do
      local username = players:get(i):getUsername()
      if not serverPointsData[username] then serverPointsData[username] = 0 end
      serverPointsData[username] = serverPointsData[username] + SandboxVars.ServerPoints.PointsPerTick
  end
end

local function LoadListings()
  local fileReader = getFileReader("ServerPointsListings.ini", true)
  local lines = {}
  local line = fileReader:readLine()
  while line do
      table.insert(lines, line)
      line = fileReader:readLine()
  end
  fileReader:close()
  local listingsString = table.concat(lines, "\n")
  local listingsFunction, err = loadstring(listingsString)
  if not listingsFunction then
      print("Error loading listings: " .. tostring(err))
      listings = { ["Missing Configuration"] = {} }
  else
      listings = listingsFunction() or { ["Missing Configuration"] = {} }
  end
end

Events.OnInitGlobalModData.Add(function(isNewGame)
  serverPointsData = ModData.getOrCreate("serverPointsData")

  LoadListings()

  if SandboxVars.ServerPoints.PointsFrequency == 2 then
      Events.EveryTenMinutes.Add(PointsTick)
  elseif SandboxVars.ServerPoints.PointsFrequency == 3 then
      Events.EveryHours.Add(PointsTick)
  elseif SandboxVars.ServerPoints.PointsFrequency == 4 then
      Events.EveryDays.Add(PointsTick)
  end
end)

local ServerPointsCommands = {}

function ServerPointsCommands.addTrait(module, command, player, args)
  local trait = args.trait
  print("Received addTrait command for trait: " .. trait) -- Debugging print statement
  if trait and not player:HasTrait(trait) then
      player:getTraits():add(trait)
      player:Say("Trait added: " .. trait)
  end
  sendServerCommand("ServerPoints", "addTrait", { args[1] })
end

function ServerPointsCommands.removeTrait(module, command, player, args)
  local trait = args.trait
  print("Received removeTrait command for trait: " .. trait) -- Debugging print statement
  if trait and player:HasTrait(trait) then
      player:getTraits():remove(trait)
      player:Say("Trait removed: " .. trait)
  end
  sendServerCommand("ServerPoints", "removeTrait", { args[1] })
end

function ServerPointsCommands.repairVehicle(module, command, player, args)
  local vehicle = getVehicleById(args[1])
  if vehicle then
      -- Repair all vehicle parts instantly
      for partIndex = 0, vehicle:getPartCount() - 1 do
          local part = vehicle:getPartByIndex(partIndex)
          if part and part:getCondition() < 100 then
              part:setCondition(100)
          end
      end
      -- Broadcast the repair to all clients
      sendServerCommand("ServerPoints", "repairVehicle", { args[1] })
      print("[Server Points] -- Vehicle repaired at ID: " .. args[1])
  end
end

function ServerPointsCommands.get(module, command, player, args)
  sendServerCommand(player, module, command, { serverPointsData[args and args[1] or player:getUsername()] or 0 })
end
-- ServerPointsCommands.get("Server", command, player, args)

function ServerPointsCommands.buy(module, command, player, args)
  print(string.format("[SERVER POINTS] %s bought %s for %d points", player:getUsername(), args[2], args[1]))
  if not serverPointsData[player:getUsername()] then serverPointsData[player:getUsername()] = 0 end
  serverPointsData[player:getUsername()] = serverPointsData[player:getUsername()] - math.abs(args[1])
  print("Bought: " .. args[2] .. " for " .. args[1] .. " points")
end

function ServerPointsCommands.vehicle(module, command, player, args)
  local vehicle = addVehicleDebug(args[1], IsoDirections.S, nil, player:getSquare())
  for i = 0, vehicle:getPartCount() - 1 do
      local container = vehicle:getPartByIndex(i):getItemContainer()
      if container then
          container:removeAllItems()
      end
  end
  vehicle:repair()
  player:sendObjectChange("addItem", { item = vehicle:createVehicleKey() })
end

function ServerPointsCommands.add(module, command, player, args)
  print(string.format("[SERVER POINTS] %s gave %s %d points", player:getUsername(), args[1], args[2]))
  if not serverPointsData[args[1]] then serverPointsData[args[1]] = 0 end
  serverPointsData[args[1]] = serverPointsData[args[1]] + args[2]
end

function ServerPointsCommands.check(module, command, player, args)
  return serverPointsData[player:getUsername()] or 0
end

function ServerPointsCommands.load(module, command, player, args)
  sendServerCommand(player, module, command, listings)
end

function ServerPointsCommands.reload(module, command, player, args)
  LoadListings()
end

function OnServerCommand(module, command, arguments)
  if module == "ServerPoints" and command == "get" then
      ServerPointsUI.instance.points = arguments[1] or 0
      print("[ServerPoint] points: " .. tostring(arguments[1])) -- Print the received points
      return ServerPointsUI.instance.points
  end
end


function OnClientCommand(module, command, player, args)
  if module == "ServerPoints" and ServerPointsCommands[command] then
      ServerPointsCommands[command](module, command, player, args)
  end
end

Events.OnClientCommand.Add(OnClientCommand)

return ServerPointsCommands
