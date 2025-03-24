local SimpleUI = ISPanel:derive("SimpleUI")

function SimpleUI:initialise()
  ISPanel.initialise(self)
    -- Create a dedicated field for balance that can be updated
    self.balanceLabel = ISLabel:new(10, 10, 20, "SERVER POINTS TRANSFER", 1, 1, 1, 1, UIFont.Small, true)
    self.balanceLabel:initialise()
    self:addChild(self.balanceLabel)

    -- Update the balance display
    self:updateBalanceDisplay()

    -- Add close button to hide the UI
    local closeButton = ISButton:new(self:getWidth() - 30, 10, 20, 20, "X", self, SimpleUI.onClose)
    closeButton:initialise()
    closeButton:instantiate()
    self:addChild(closeButton)

    -- Add a label for the transfer points input
    local transferLabel = ISLabel:new(10, 40, 20, "Transfer Points:", 1, 1, 1, 1, UIFont.Small, true)
    transferLabel:initialise()
    self:addChild(transferLabel)

    -- Add a text input field for the transfer points
    self.transferInput = ISTextEntryBox:new("0", 120, 40, 100, 20)
    self.transferInput:initialise()
    self:addChild(self.transferInput)

    -- Add a label for the recipient dropdown/textbox
    local recipientLabel = ISLabel:new(10, 70, 20, "Recipient Username:", 1, 1, 1, 1, UIFont.Small, true)
    recipientLabel:initialise()
    self:addChild(recipientLabel)

    -- Add a dropdown for the recipient username
    self.recipientDropdown = ISComboBox:new(120, 70, 160, 20)  -- Made wider
    self.recipientDropdown:initialise()
    self:addChild(self.recipientDropdown)

    -- Add a checkbox to toggle between dropdown and manual entry
    self.manualEntryCheckbox = ISTickBox:new(10, 100, 150, 20, "Manual Entry", self, SimpleUI.onToggleManualEntry)
    self.manualEntryCheckbox:initialise()
    self.manualEntryCheckbox:addOption("Manual Entry")
    self:addChild(self.manualEntryCheckbox)

    -- Add a textbox for manual recipient entry (position below dropdown)
    self.manualRecipientInput = ISTextEntryBox:new("", 120, 100, 160, 20)  -- Made wider
    self.manualRecipientInput:initialise()
    self.manualRecipientInput:setVisible(false) -- Hidden by default
    self:addChild(self.manualRecipientInput)

    -- Populate the dropdown with online players
    self:populateRecipientDropdown()

    -- Move buttons lower for better spacing
    -- Add a button to initiate the transfer
    local transferButton = ISButton:new(120, 130, 80, 25, "Transfer", self, SimpleUI.onTransferPoints)
    transferButton:initialise()
    self:addChild(transferButton)

    -- Add a refresh button to repopulate the dropdown AND update balance
    local refreshButton = ISButton:new(210, 130, 80, 25, "Refresh", self, SimpleUI.onRefreshPlayers)
    refreshButton:initialise()
    self:addChild(refreshButton)
end

-- Function to update the balance display
function SimpleUI:updateBalanceDisplay()
    local username = getPlayer():getUsername()
    local clientBalance = GlobalMethods.getPlayerPoints(username)

    -- Format the balance with commas for thousands
    local formattedBalance = tostring(clientBalance)
    if tonumber(clientBalance) >= 1000 then
        formattedBalance = string.format("%d,%03d", math.floor(clientBalance/1000), clientBalance%1000)
    end

    self.balanceLabel:setName("SERVER POINTS:  " .. formattedBalance)
    return clientBalance
end

-- Function to handle closing the UI
function SimpleUI:onClose()
    self:setVisible(false)

    -- If this UI is part of MainScreen, also set it invisible there
    if MainScreen and MainScreen.instance and MainScreen.instance.simpleUI then
        MainScreen.instance.simpleUI:setVisible(false)
    end
end

function SimpleUI:onToggleManualEntry(index, selected)
    print("Manual entry toggled: " .. tostring(selected))
    self.recipientDropdown:setVisible(not selected)
    self.manualRecipientInput:setVisible(selected)
end

function SimpleUI:getOnlinePlayers()
    local onlineplayers = getOnlinePlayers()
    local playerList = {}
    for i = 0, onlineplayers:size() - 1 do
        local player = onlineplayers:get(i)
        table.insert(playerList, player:getUsername())
    end
    table.insert(playerList, "admin")
    return playerList
end

function SimpleUI:populateRecipientDropdown()
    self.recipientDropdown:clear()
    local onlinePlayers = self:getOnlinePlayers()
    for _, player in ipairs(onlinePlayers) do
        self.recipientDropdown:addOption(player)
    end
end

function SimpleUI:playSuccessSound()
    getSoundManager():PlaySound("success", false, 0)
end

function SimpleUI:getSelectedRecipient()
    -- Get recipient based on input mode (dropdown or manual)
    if self.manualEntryCheckbox:isSelected(1) then
        return self.manualRecipientInput:getText()
    else
        return self.recipientDropdown:getSelectedText()
    end
end

-- Update the onTransferPoints function to refresh the balance after transfer
function SimpleUI:onTransferPoints()
  local points = tonumber(self.transferInput:getText())
  local recipient = self:getSelectedRecipient()
  local player = getPlayer()
  local sender = player:getUsername()

  if points and points > 0 and recipient and recipient ~= "" then
      if sender == 'ERA' then
          player:Say("Gak bisa transfer pake akun ini sa oy!")
      else
          -- Debug balance checking
          local senderBalance = GlobalMethods.getPlayerPoints(sender)
          print("DEBUG: Raw balance value: " .. tostring(senderBalance))

          -- Convert to number explicitly
          senderBalance = tonumber(senderBalance or 0)
          print("DEBUG: Transfer request - Balance: " .. tostring(senderBalance) .. ", Transfer amount: " .. tostring(points))

          -- Check if balance is sufficient
          if not senderBalance or senderBalance < points then
              player:Say("Insufficient balance: " .. tostring(senderBalance) .. "/" .. tostring(points))
              return
          end

          -- Process the transfer
          GlobalMethods.addPlayerPoints(recipient, points)
          print("Transferring " .. points .. " points to " .. recipient)
          GlobalMethods.takePlayerPoints(sender, points)
          print("Adjusting " .. points .. " points for " .. sender)
          player:Say("Transferan sukses coy!")

          -- Send notification to the recipient via the ServerAlert system
          sendClientCommand("ServerPoints", "notifyTransfer", {
              recipient = recipient,
              sender = sender,
              points = points
          })

          self:updateBalanceDisplay()
          self:playSuccessSound()
      end
  else
      player:Say("Yang bener doonng ... ")
      print("Invalid points value or recipient username")
  end
end

-- Ensure refresh function updates both player list and balance
function SimpleUI:onRefreshPlayers()
    self:populateRecipientDropdown()
    self:updateBalanceDisplay()
end

function SimpleUI:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    return o
end

local function onServerCommand(module, command, args)
  if module == "ServerPoints" and command == "showTransferNotification" then
      local sender = args.sender
      local points = args.points

      -- Create notification message
      local message = string.format("You received %d points from %s", points, sender)

      -- Try to use chat notification first
      local chatNotificationSuccess = false
      -- if ISChat.instance then
      --     -- Use pcall to catch any potential errors
      --     local success = pcall(function()
      --         ISChat.addLineToChat(message, 1, 1, 0, 1, 0) -- Yellow text
      --         -- ISChat.instance:bringToTop()
      --     end)
      --     chatNotificationSuccess = success
      -- end

      -- If chat notification failed, use server alert as fallback
      if not chatNotificationSuccess then
          -- Use the ServerAlert system as fallback
          sendClientCommand("ServerAlert", "sendAlert", {
              message = message,
              color = "<RGB:1,1,0>", -- Yellow color
              username = "Points System",
              targetPlayer = getPlayer():getUsername()
          })

          -- Also show a popup for redundancy
          getPlayer():Say(message)
      end
  end
end

Events.OnServerCommand.Add(onServerCommand)

return SimpleUI