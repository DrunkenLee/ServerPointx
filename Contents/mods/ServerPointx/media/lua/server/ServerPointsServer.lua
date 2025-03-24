
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
  local playerSquare = player:getSquare()
  local vehicle = addVehicleDebug(args[1], IsoDirections.S, nil, playerSquare)

  local spawnSuccess = false
  if vehicle then
      local vehicleID = vehicle:getId()
      local retrievedVehicle = getVehicleById(vehicleID)
      local vehicleSquare = vehicle:getCurrentSquare()

      print(vehicleID, retrievedVehicle, vehicleSquare)

      if retrievedVehicle then
          -- Vehicle truly spawned successfully
          spawnSuccess = true
          for i = 0, vehicle:getPartCount() - 1 do
              local container = vehicle:getPartByIndex(i):getItemContainer()
              if container then
                  container:removeAllItems()
              end
          end
          vehicle:repair()
          player:sendObjectChange("addItem", { item = vehicle:createVehicleKey() })

          -- Send success message back to client
          sendServerCommand(player, "ServerPoints", "vehicleSpawnResult", {
              success = true,
              message = "Vehicle spawned successfully!"
          })
          print(string.format("[SERVER POINTS] %s successfully spawned vehicle %s", player:getUsername(), args[1]))
      else
          if vehicle then
              vehicle:permanentlyRemove()
          end
          spawnSuccess = false
      end
  end

  -- If spawn failed for any reason
  if not spawnSuccess then
      -- Vehicle spawn failed - send failure message back to client
      sendServerCommand(player, "ServerPoints", "vehicleSpawnResult", {
          success = false,
          message = "Failed to spawn vehicle. You need to be in an open area with enough space.",
          vehicleType = args[1]
      })
      print(string.format("[SERVER POINTS] Failed to spawn vehicle %s for %s - location may be obstructed",
          args[1], player:getUsername()))
  end

  return spawnSuccess
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

function ServerPointsCommands.notifyTransfer(module, command, player, args)
  local recipient = args.recipient
  local sender = args.sender
  local points = args.points

  -- Find the recipient player instance
  local players = getOnlinePlayers()
  for i = 0, players:size() - 1 do
      local onlinePlayer = players:get(i)
      if onlinePlayer:getUsername() == recipient then
          -- Send notification to recipient
          sendServerCommand(onlinePlayer, "ServerPoints", "showTransferNotification", {
              sender = sender,
              points = points
          })
          print(string.format("[SERVER POINTS] Notification sent to %s about transfer of %d points from %s",
              recipient, points, sender))
          break
      end
  end
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
