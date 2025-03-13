require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"

RepairVehicleAction = ISBaseTimedAction:derive("RepairVehicleAction")

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
        local player = getPlayer()
        if player then
            player:Say("My vehicle has been repaired! Free Charge")
        end
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

local function repairVehiclesInZones()
    local cell = getCell()
    if not cell then return end -- Ensure cell is available

    local vehicles = cell:getVehicles() -- Get all vehicles
    local player = getPlayer()
    if not player then return end -- Ensure player is available

    local px, py = player:getX(), player:getY() -- Player coordinates

    -- Hardcoded repair zones with the new zone added
    local repairAreas = {
        {enabled = true, minX = 9384, maxX = 9388, minY = 11180, maxY = 11185}, -- New zone added
        {enabled = true, minX = 7242, maxX = 7251, minY = 5503, maxY = 5509},
        {enabled = true, minX = 12715, maxX = 12724, minY = 5074, maxY = 5086}
    }

    -- Check if the player is inside a repair zone
    local playerInRepairZone = false
    for _, area in ipairs(repairAreas) do
        if area.enabled and px >= area.minX and px <= area.maxX and py >= area.minY and py <= area.maxY then
            playerInRepairZone = true
            break
        end
    end

    if not playerInRepairZone then return end -- Exit if player is not in a repair zone

    -- Repair vehicles in zones
    if not vehicles or vehicles:isEmpty() then return end -- Ensure vehicles exist
    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            local vx, vy = vehicle:getX(), vehicle:getY()
            -- Check if the vehicle is inside the same repair zone as the player
            for _, area in ipairs(repairAreas) do
                if area.enabled and vx >= area.minX and vx <= area.maxX and vy >= area.minY and vy <= area.maxY then
                    -- Send server command to repair the vehicle
                    sendClientCommand("ServerPoints", "repairVehicle", { vehicle:getId() })
                    break -- Stop checking other areas once we find one
                end
            end
        end
    end
end

local function imInRepairZone()
    local player = getPlayer()
    if not player then return end -- Ensure player is available

    local px, py = player:getX(), player:getY() -- Player coordinates

    -- Hardcoded repair zones with the new zone added
    local repairAreas = {
        {enabled = true, minX = 9384, maxX = 9388, minY = 11180, maxY = 11185}, -- New zone added
        {enabled = true, minX = 7242, maxX = 7251, minY = 5503, maxY = 5509},
        {enabled = true, minX = 12715, maxX = 12724, minY = 5074, maxY = 5086}
    }

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
