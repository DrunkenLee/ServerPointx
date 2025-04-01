-- Create global namespace
if not ServerPointx then ServerPointx = {} end
if not ServerPointx.Overseer then ServerPointx.Overseer = {} end

-- Variable to track if the player is an authorized overseer
local isOverseerAuthorized = false

-- Overseer features toggle states
local overseerFeatures = {
    infiniteAmmo = false,
    seeEveryone = false
}

-- Improved debug function
ServerPointx.Overseer.debug = function()
    print("Authorization status: " .. tostring(isOverseerAuthorized))
    print("Username: " .. getPlayer():getUsername())

    -- List current Overseer features status
    print("Feature status:")
    print("- Infinite Ammo: " .. tostring(overseerFeatures.infiniteAmmo))
    print("- See Everyone: " .. tostring(overseerFeatures.seeEveryone))

    return "Authorization status: " .. tostring(isOverseerAuthorized)
end

-- Debug function to force authorization (for testing only)
ServerPointx.Overseer.forceAuth = function()
    isOverseerAuthorized = true
    print("Authorization forced to TRUE")
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
    if module == "OverseerPerk" and command == "SetAuthorized" then
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
    end
end

-- Toggle the infinite ammo feature
local function applyInfiniteAmmo()
    if not overseerFeatures.infiniteAmmo then return end

    local player = getSpecificPlayer(0)
    if player then
        local items = player:getInventory():getItems()
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if instanceof(item, "HandWeapon") and item:isRanged() then
                -- Set current ammo to max
                if item:getCurrentAmmoCount() < item:getMaxAmmo() then
                    item:setCurrentAmmoCount(item:getMaxAmmo())
                end
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

-- Create a simple UI to toggle features
local function createOverseerMenu()
  if not isOverseerAuthorized then return end

  local modal = ISModalDialog:new(0, 0, 280, 180, "Overseer Menu", true, nil, function() end)
  modal:initialise()
  modal:addToUIManager()
  modal:setAlwaysOnTop(true)

  local y = 50
  -- Create infiniteAmmoBtn first
  local infiniteAmmoBtn = ISButton:new(40, y, 200, 25, "Infinite Ammo: " .. (overseerFeatures.infiniteAmmo and "ON" or "OFF"), nil, nil)
  infiniteAmmoBtn:initialise()

  -- Set the onClick function separately after initialization
  infiniteAmmoBtn.onClick = function()
      overseerFeatures.infiniteAmmo = not overseerFeatures.infiniteAmmo
      -- infiniteAmmoBtn:setTitle("Infinite Ammo: " .. (overseerFeatures.infiniteAmmo and "ON" or "OFF"))
  end

  modal:addChild(infiniteAmmoBtn)

  y = y + 35
  -- Create seeEveryoneBtn first
  local seeEveryoneBtn = ISButton:new(40, y, 200, 25, "See Everyone: " .. (overseerFeatures.seeEveryone and "ON" or "OFF"), nil, nil)
  seeEveryoneBtn:initialise()

  -- Set the onClick function separately after initialization
  seeEveryoneBtn.onClick = function()
      overseerFeatures.seeEveryone = not overseerFeatures.seeEveryone
      seeEveryoneBtn:setTitle("See Everyone: " .. (overseerFeatures.seeEveryone and "ON" or "OFF"))
  end

  modal:addChild(seeEveryoneBtn)
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
Events.OnPlayerUpdate.Add(applyInfiniteAmmo)
Events.OnPreUIDraw.Add(highlightAllPlayers)