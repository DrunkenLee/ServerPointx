-- Import cheat handler for features that require it
if not isClient() or isAdmin() or isCoopHost() then
  require "ISCheatHandler"
end

-- Create global namespace
if not ServerPointx then ServerPointx = {} end
if not ServerPointx.Overseer then ServerPointx.Overseer = {} end

-- Variable to track if the player is an authorized overseer
local isOverseerAuthorized = false

-- Overseer features toggle states
local overseerFeatures = {
  infiniteAmmo = false,
  seeEveryone = false,
  mapTracking = false  -- New feature to see players on map
}

-- Improved debug function
ServerPointx.Overseer.debug = function()
  print("Authorization status: " .. tostring(isOverseerAuthorized))
  print("Username: " .. getPlayer():getUsername())

  -- List current Overseer features status
  print("Feature status:")
  print("- Infinite Ammo: " .. tostring(overseerFeatures.infiniteAmmo))
  print("- See Everyone: " .. tostring(overseerFeatures.seeEveryone))
  print("- Map Tracking: " .. tostring(overseerFeatures.mapTracking))

  return "Authorization status: " .. tostring(isOverseerAuthorized)
end

-- Debug function to force authorization (for testing only)
ServerPointx.Overseer.forceAuth = function()
  isOverseerAuthorized = true
  print("Authorization forced to TRUE")
  return "Authorization forced to TRUE. Press O to open menu."
end

-- Request authorization from server with retry capability
function requestOverseerAuthorization()
  local username = getPlayer():getUsername()
  print("Requesting authorization for: " .. username)
  sendClientCommand("OverseerPerk", "RequestAuthorization", {})
  -- Show visual feedback that we're checking
  getPlayer():Say("Checking Overseer privileges...")
end

-- Handle server response about authorization
local function handleServerCommand(module, command, args)
  if module == "OverseerPerk" then
      if command == "SetAuthorized" then
          isOverseerAuthorized = args.isAuthorized
          print("Received auth response: " .. tostring(isOverseerAuthorized))

          -- Give user feedback
          if isOverseerAuthorized then
              print("Overseer mode available - press O to open menu")
              getPlayer():Say("Overseer privileges granted!")
          else
              print("Not authorized as overseer")
              getPlayer():Say("You don't have Overseer privileges.")
          end
      elseif command == "TestResponse" then
          print("TEST RESPONSE RECEIVED: " .. args.message)
          getPlayer():Say("Server connection working!")
      end
  end
end

-- Toggle the infinite ammo feature using ISCheat
local function applyInfiniteAmmo()
  if not overseerFeatures.infiniteAmmo then return end

  -- Only run every few frames to reduce overhead
  if (getGameTime():getWorldAgeHours() * 3600) % 30 > 1 then return end

  local player = getSpecificPlayer(0)
  if not player then return end

  local items = player:getInventory():getItems()
  for i = 0, items:size() - 1 do
      local item = items:get(i)
      if instanceof(item, "HandWeapon") and item:isRanged() then
          -- If weapon is below max ammo
          if item:getCurrentAmmoCount() < item:getMaxAmmo() then
              -- Try to use the ISCheat system if available
              if ISCheatHandler and ISCheatHandler.addItem then
                  -- Save current equipped state
                  local wasEquipped = player:getPrimaryHandItem() == item
                  local wasInHotbar = false
                  for j=1,10 do
                      if player:getAttachedItem("HotbarAttachment"..j) == item then
                          wasInHotbar = true
                          break
                      end
                  end

                  -- Get item data for later
                  local itemType = item:getFullType()
                  local condition = item:getCondition()

                  -- Remove the old item
                  player:getInventory():Remove(item)

                  -- Add the new item with full ammo
                  ISCheatHandler.addItem(player:getPlayerNum(), itemType, 1, item:getMaxAmmo())

                  -- Since we can't directly restore equipped state, just inform the player
                  if wasEquipped or wasInHotbar then
                      print("Re-equipped weapon with full ammo")
                  end
              else
                  -- Fallback to direct manipulation if ISCheat is not available
                  item:setCurrentAmmoCount(item:getMaxAmmo())
              end
              break -- Only process one weapon per update to avoid issues
          end
      end
  end
end

-- Function to highlight all players on screen
local function highlightAllPlayers()
  if not overseerFeatures.seeEveryone then return end

  -- Get all online players
  local players = getOnlinePlayers()
  if not players then return end

  local localPlayer = getSpecificPlayer(0)

  -- Loop through all players and make them visible/highlighted
  for i = 0, players:size() - 1 do
      local player = players:get(i)
      if player ~= localPlayer then
          player:setHighlighted(true)
          player:setAlphaAndTarget(1.0, 1.0) -- Make fully visible
      end
  end
end

-- Function to show all players on the map
local function showPlayersOnMap()
    -- Skip if feature is disabled
    if not overseerFeatures.mapTracking then return end

    -- Get the world map UI
    local mapUI = getWorldMapInstance()
    if not mapUI then return end

    -- Get all online players
    local players = getOnlinePlayers()
    if not players then return end

    local localPlayer = getSpecificPlayer(0)

    -- Add all players to the map
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player ~= localPlayer then
            -- Add player marker on map
            local x = player:getX()
            local y = player:getY()
            local username = player:getUsername()

            -- Use the map API to add a marker (color: red)
            mapUI:addPlayerPosition(player, username, 0.9, 0.1, 0.1)
        end
    end
end

-- Create a simple UI to toggle features
local function createOverseerMenu()
  if not isOverseerAuthorized then
      getPlayer():Say("You don't have Overseer privileges.")
      return
  end

  local modal = ISModalDialog:new(0, 0, 280, 220, "Overseer Menu", true, nil, function() end)
  modal:initialise()
  modal:addToUIManager()
  modal:setAlwaysOnTop(true)

  local y = 50
  -- Create infiniteAmmoBtn first
  local infiniteAmmoBtn = ISButton:new(40, y, 200, 25, "Infinite Ammo: " .. (overseerFeatures.infiniteAmmo and "ON" or "OFF"), nil, function()
      overseerFeatures.infiniteAmmo = not overseerFeatures.infiniteAmmo
      local success, error = pcall(function()
        infiniteAmmoBtn:setTitle("Infinite Ammo: " .. (overseerFeatures.infiniteAmmo and "ON" or "OFF"))
      end)
      if not success then
        print("Error setting button title: " .. tostring(error))
      end
      getPlayer():Say("Infinite ammo " .. (overseerFeatures.infiniteAmmo and "enabled" or "disabled"))
  end)
  infiniteAmmoBtn:initialise()
  modal:addChild(infiniteAmmoBtn)

  y = y + 35
  -- Create seeEveryoneBtn
  local seeEveryoneBtn = ISButton:new(40, y, 200, 25, "See Everyone: " .. (overseerFeatures.seeEveryone and "ON" or "OFF"), nil, function()
      overseerFeatures.seeEveryone = not overseerFeatures.seeEveryone
      local success, error = pcall(function()
        seeEveryoneBtn:setTitle("See Everyone: " .. (overseerFeatures.seeEveryone and "ON" or "OFF"))
      end)
      if not success then
        print("Error setting button title: " .. tostring(error))
      end
      getPlayer():Say("See everyone " .. (overseerFeatures.seeEveryone and "enabled" or "disabled"))
  end)
  seeEveryoneBtn:initialise()
  modal:addChild(seeEveryoneBtn)

  y = y + 35
  -- Create mapTrackingBtn
  local mapTrackingBtn = ISButton:new(40, y, 200, 25, "Map Tracking: " .. (overseerFeatures.mapTracking and "ON" or "OFF"), nil, function()
      overseerFeatures.mapTracking = not overseerFeatures.mapTracking
      local success, error = pcall(function()
        mapTrackingBtn:setTitle("Map Tracking: " .. (overseerFeatures.mapTracking and "ON" or "OFF"))
      end)
      if not success then
        print("Error setting button title: " .. tostring(error))
      end
      getPlayer():Say("Map tracking " .. (overseerFeatures.mapTracking and "enabled" or "disabled"))
  end)
  mapTrackingBtn:initialise()
  modal:addChild(mapTrackingBtn)
end

-- Expose function through the global namespace
ServerPointx.Overseer.openMenu = function()
  createOverseerMenu()
end

-- Open menu when O key is pressed (only for authorized users)
local function onKeyPressed(key)
  -- Alt+O key combination to request authorization
  if key == Keyboard.KEY_O and isKeyDown(Keyboard.KEY_LMENU) then
      requestOverseerAuthorization()
  end

  -- Normal O key to open menu if authorized
  if key == Keyboard.KEY_O and not isKeyDown(Keyboard.KEY_LMENU) and isOverseerAuthorized then
      createOverseerMenu()
  end
end

-- Add a function to manually request authorization
ServerPointx.Overseer.requestAuth = function()
  requestOverseerAuthorization()
  return "Authorization request sent. Check console for results."
end

-- Add a test function that works regardless of authorization
function TestOverseerMenu()
  -- Temporarily override the auth check
  local originalAuth = isOverseerAuthorized
  isOverseerAuthorized = true

  createOverseerMenu()

  -- Restore the original auth state
  isOverseerAuthorized = originalAuth

  return "Test menu opened. Original auth status: " .. tostring(originalAuth)
end

-- Add a direct test command that bypasses the normal flow
ServerPointx.Overseer.testServerComm = function()
  print("TESTING SERVER COMMUNICATION")
  print("Sending test command to server")

  -- Send a simple test command the server can respond to
  sendClientCommand("OverseerPerk", "TestConnection", {})

  -- Log the result
  print("Test command sent - check server console")
  getPlayer():Say("Testing server connection...")

  return "Test command sent. Check server console."
end

-- Initialize event handlers
Events.OnGameStart.Add(requestOverseerAuthorization)
Events.OnServerCommand.Add(handleServerCommand)
Events.OnKeyPressed.Add(onKeyPressed)
Events.OnTick.Add(applyInfiniteAmmo)  -- Changed from OnPlayerUpdate for better performance
Events.OnPreUIDraw.Add(highlightAllPlayers)
Events.OnWorldMap.Add(showPlayersOnMap)  -- Add players to the map when it's opened