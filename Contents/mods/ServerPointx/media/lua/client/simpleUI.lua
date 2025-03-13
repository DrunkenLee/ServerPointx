local SimpleUI = ISPanel:derive("SimpleUI")

function SimpleUI:initialise()
    ISPanel.initialise(self)
    self:addChild(ISLabel:new(10, 10, 20, "SERVER POINTS TRANSFER", 1, 1, 1, 1, UIFont.Small, true))

    -- Add a close button
    local closeButton = ISButton:new(self:getWidth() - 60, 10, 20, 20, "CLOSE", self, function()
        self:setVisible(false)
    end)
    closeButton:initialise()
    self:addChild(closeButton)

    -- Add a label for the transfer points input
    local transferLabel = ISLabel:new(10, 40, 20, "Transfer Points:", 1, 1, 1, 1, UIFont.Small, true)
    transferLabel:initialise()
    self:addChild(transferLabel)

    -- Add a text input field for the transfer points
    self.transferInput = ISTextEntryBox:new("0", 120, 40, 100, 20)
    self.transferInput:initialise()
    self:addChild(self.transferInput)

    -- Add a label for the recipient dropdown
    local recipientLabel = ISLabel:new(10, 70, 20, "Recipient Username:", 1, 1, 1, 1, UIFont.Small, true)
    recipientLabel:initialise()
    self:addChild(recipientLabel)

    -- Add a dropdown for the recipient username
    self.recipientDropdown = ISComboBox:new(120, 70, 100, 20)
    self.recipientDropdown:initialise()
    self:addChild(self.recipientDropdown)

    -- Populate the dropdown with online players
    self:populateRecipientDropdown()

    -- Add a button to initiate the transfer
    local transferButton = ISButton:new(230, 70, 60, 20, "Transfer", self, SimpleUI.onTransferPoints)
    transferButton:initialise()
    self:addChild(transferButton)

    -- Add a refresh button to repopulate the dropdown
    local refreshButton = ISButton:new(300, 70, 60, 20, "Refresh", self, SimpleUI.onRefreshPlayers)
    refreshButton:initialise()
    self:addChild(refreshButton)
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

function SimpleUI:onTransferPoints()
    local points = tonumber(self.transferInput:getText())
    local recipient = self.recipientDropdown:getSelectedText()
    local player = getPlayer()
    local sender = player:getUsername()
    if points and points > 0 and recipient and recipient ~= "" then
        if sender == 'ERA' then
            player:Say("Gak bisa transfer pake akun ini sa oy!")
        else
            local senderBalance = GlobalMethods.getPlayerPoints(sender) or 0
            if senderBalance < points then
                player:Say("Insufficient balance")
                return
            end
            GlobalMethods.addPlayerPoints(recipient, points)
            print("Transferring " .. points .. " points to " .. recipient)
            GlobalMethods.takePlayerPoints(sender, points)
            print("Adjusting " .. points .. " points for " .. sender)
            player:Say("Transferan sukses coy!")
            self:playSuccessSound()
        end
    else
        player:Say("Yang bener doonng ... ")
        print("Invalid points value or recipient username")
    end
end

function SimpleUI:onRefreshPlayers()
    self:populateRecipientDropdown()
end

function SimpleUI:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    return o
end

return SimpleUI