require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"

RepairVehicleAction = ISBaseTimedAction:derive("RepairVehicleAction")

-- Table to store the last repair time for each player
local lastRepairTime = {}
-- Table to store the last message time for each player
local lastMessageTime = {}

function RepairVehicleAction:isValid()
    return true
end

function RepairVehicleAction:update()
    -- Update logic if needed
end

function RepairVehicleAction:start()
    -- Start logic if needed
    local player = getPlayer()
    if player then
        player:Say("Repairing vehicle...")
    end
end

function RepairVehicleAction:stop()
    ISBaseTimedAction.stop(self)
end

function RepairVehicleAction:perform()
    -- Perform the repair logic
    local vehicle = self.vehicle
    if vehicle then
        for partIndex = 0, vehicle:getPartCount() - 1 do
            local part = vehicle:getPartByIndex(partIndex)
            if part and part:getCondition() < 100 then
                part:setCondition(100)
            end
        end
        print("Vehicle repaired at ID: " .. vehicle:getId())
        -- Play success sound
        self:playSuccessSound()
    end
    -- Remove timed action from queue
    ISBaseTimedAction.perform(self)
end

function RepairVehicleAction:playSuccessSound()
    getSoundManager():PlaySound("repairing", false, 0)
end

function RepairVehicleAction:new(player, vehicle, time)
    local o = ISBaseTimedAction.new(self, player)
    o.character = player
    o.vehicle = vehicle
    o.maxTime = time
    return o
end

-- Table to store the last repair time for each player
local lastRepairTime = {}

local function repairVehiclesInZones()
    local cell = getCell()
    if not cell then return end -- Ensure cell is available

    local player = getPlayer()
    if not player then return end -- Ensure player is available

    local vehicle = player:getVehicle()
    if not vehicle then return end -- Ensure player is in a vehicle

    local px, py = player:getX(), player:getY() -- Player coordinates

    -- Hardcoded repair zones with the new zones added
    local repairAreas = {
        {enabled = true, minX = 9384, maxX = 9388, minY = 11180, maxY = 11185}, -- Existing zone
        {enabled = true, minX = 7242, maxX = 7251, minY = 5503, maxY = 5509}, -- Existing zone
        {enabled = true, minX = 12715, maxX = 12724, minY = 5074, maxY = 5086}, -- Existing zone
    }

    -- -- Add new zones from sandbox options
    -- local repairArea1Coords = parseCoordinates(SandboxVars.ServerPoints.RepairArea1)
    -- table.insert(repairAreas, {enabled = true, minX = repairArea1Coords[1], maxX = repairArea1Coords[2], minY = repairArea1Coords[3], maxY = repairArea1Coords[4]})

    -- local repairArea2Coords = parseCoordinates(SandboxVars.ServerPoints.RepairArea2)
    -- table.insert(repairAreas, {enabled = true, minX = repairArea2Coords[1], maxX = repairArea2Coords[2], minY = repairArea2Coords[3], maxY = repairArea2Coords[4]})

    local playerInRepairZone = false
    for _, area in ipairs(repairAreas) do
        if area.enabled and px >= area.minX and px <= area.maxX and py >= area.minY and py <= area.maxY then
            playerInRepairZone = true
            break
        end
    end

    if not playerInRepairZone then return end

    local playerTierValue = tonumber(PlayerTierHandler.getPlayerTierValue(player)) or 1
    if playerTierValue < 3 then
        player:Say("I need to upgrade my tier to repair vehicles.")
        return
    end

    local playerId = player:getOnlineID()
    local currentTime = getGameTime():getWorldAgeHours()
    local lastRepair = lastRepairTime[playerId] or 0
    local cooldown = 24 * 24
    local isVIP = tonumber(PlayerTitleHandler.getPlayerTitle(player)) or 0
    if isVIP == 1 then cooldown = cooldown / 2 end
    if isVIP == 2 then cooldown = cooldown / 4 end
    if isVIP == 3 then cooldown = cooldown / 6 end

    if currentTime - lastRepair < cooldown then
      local lastMessage = lastMessageTime[playerId] or 0
      local messageCooldown = 10 / 60 -- 1 minute cooldown for messages (1/60 of an hour)

      if currentTime - lastMessage >= messageCooldown then
          local remainingTime = cooldown - (currentTime - lastRepair)

          -- Convert in-game hours to real-time hours and minutes
          local realTimeHours = math.floor(remainingTime / 24) -- 24 in-game hours = 1 real-time hour
          local realTimeMinutes = math.floor((remainingTime % 24) * (60 / 24)) -- Convert remaining in-game hours to real-time minutes

          player:Say("!" .. realTimeHours .. " hours and " .. realTimeMinutes .. " minutes remaining until I can repair again.")
          lastMessageTime[playerId] = currentTime
      end
      return
    end

    -- Update the last repair time
    lastRepairTime[playerId] = currentTime
    sendClientCommand("ServerPoints", "repairVehicle", { vehicle:getId() })
end

local function parseCoordinates(coordString)
  local coords = {}
  for coord in string.gmatch(coordString, "%d+") do
      table.insert(coords, tonumber(coord))
  end
  return coords
end

local function imInRepairZone()
  local player = getPlayer()
  if not player then return end -- Ensure player is available

  local px, py = player:getX(), player:getY() -- Player coordinates

  -- Hardcoded repair zones with the new zones added
  local repairAreas = {
      {enabled = true, minX = 9384, maxX = 9388, minY = 11180, maxY = 11185}, -- Existing zone
      {enabled = true, minX = 7242, maxX = 7251, minY = 5503, maxY = 5509}, -- Existing zone
      {enabled = true, minX = 12715, maxX = 12724, minY = 5074, maxY = 5086}, -- Existing zone
  }

  -- Add new zones from sandbox options
  local repairArea1Coords = parseCoordinates(SandboxVars.ServerPoints.RepairArea1)
  table.insert(repairAreas, {enabled = true, minX = repairArea1Coords[1], maxX = repairArea1Coords[2], minY = repairArea1Coords[3], maxY = repairArea1Coords[4]})

  local repairArea2Coords = parseCoordinates(SandboxVars.ServerPoints.RepairArea2)
  table.insert(repairAreas, {enabled = true, minX = repairArea2Coords[1], maxX = repairArea2Coords[2], minY = repairArea2Coords[3], maxY = repairArea2Coords[4]})

  -- Check if the player is inside a repair zone
  for _, area in ipairs(repairAreas) do
      if area.enabled and px >= area.minX and px <= area.maxX and py >= area.minY and py <= area.maxY then
          player:Say("I am inside a repair zone!, I can repair my vehicle here if I EXIT the vehicle")
          break -- Stop checking once a zone is found
      end
  end
end

-- Add a handler for the server command to repair the vehicle
local function onServerCommand(module, command, args)
    if module == "ServerPoints" and command == "repairVehicle" then
        local vehicle = getVehicleById(args[1])
        if vehicle then
            local player = getPlayer()
            if player then
                -- Queue the timed action for repairing the vehicle
                ISTimedActionQueue.add(RepairVehicleAction:new(player, vehicle, 300)) -- 300 ticks = 3 seconds
            end
        end
    end
end

Events.OnServerCommand.Add(onServerCommand)

local function restrictLegendWeapon()
    local player = getPlayer()
    if not player then return end -- Ensure player is available

    local username = player:getUsername()
    local primaryItem = player:getPrimaryHandItem()
    local secondaryItem = player:getSecondaryHandItem()
    local primaryItemName = primaryItem and primaryItem:getName() or "None"
    local secondaryItemName = secondaryItem and secondaryItem:getName() or "None"
    local playerTier = PlayerTierHandler.getPlayerTier(player)
    local playerTierValue = tonumber(PlayerTierHandler.getPlayerTierValue(player)) or 1

    if primaryItem then
        -- print("Primary item equipped: " .. primaryItemName .. " Tier: " .. playerTier)
        if string.find(itemName, "Legend") and playerTierValue < 5 then
            player:setPrimaryHandItem(nil)
            player:getInventory():AddItem(primaryItem)
            player:Say("I cannot use this " .. primaryItemName .. " I need to upgrade my tier.")
        end
    else
        -- print("No primary item equipped. Tier: " .. playerTier)
    end

    if secondaryItem then
        -- print("Secondary item equipped: " .. secondaryItemName)
        if string.find(itemName, "Legend") and playerTierValue < 5 then
            player:setSecondaryHandItem(nil)
            player:getInventory():AddItem(secondaryItem)
            -- player:Say("I cannot use this " .. secondaryItemName .. " I need to upgrade my tier.")
        end
    else
        -- print("No secondary item equipped. Tier: " .. playerTier)
    end
end

local function restrictLegendWeaponOnEquip(player, item)
  if not player or not item then return end -- Ensure player and item are available

  local itemName = item:getName()
  local playerTier = PlayerTierHandler.getPlayerTier(player) or "Newbies"
  local playerTierValue = tonumber(PlayerTierHandler.getPlayerTierValue(player)) or 1

  if string.find(itemName, "Legend") and playerTierValue < 5 then
      player:getInventory():AddItem(item)
      player:setPrimaryHandItem(nil)
      player:setSecondaryHandItem(nil)
      player:getInventory():AddItem(itemName)
      player:Say("I cannot use this " .. itemName .. " I need to upgrade my tier.")
  end
end

Events.OnEquipPrimary.Add(function(player, item)
    restrictLegendWeaponOnEquip(player, item)
end)

Events.OnEquipSecondary.Add(function(player, item)
    restrictLegendWeaponOnEquip(player, item)
end)

Events.OnPlayerUpdate.Add(repairVehiclesInZones)