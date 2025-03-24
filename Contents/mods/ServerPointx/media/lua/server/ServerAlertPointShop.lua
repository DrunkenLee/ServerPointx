function SendAlertPointx(targetUsername, message, color, source)
  local players = getOnlinePlayers()
  if players then
      for i = 0, players:size() - 1 do
          local player = players:get(i)
          -- Only send to specific player if targetUsername is provided
          if not targetUsername or player:getUsername() == targetUsername then
              sendServerCommand(player, "ServerAlert", "alert", {
                  message = message or "Server notification",
                  color = color or "<RGB:1,1,0>", -- Default yellow
                  username = source or "Server",
                  options = {
                      showTime = true,
                      serverAlert = true,
                      showAuthor = true,
                  }
              })
          end
      end
  end
end

-- New function specifically for point transfer notifications
function SendPointTransferAlert(recipient, sender, points)
  local message = string.format("You received %d points from %s", points, sender)
  SendAlertPointx(
      recipient,                -- Target specific player
      message,                  -- Notification message
      "<RGB:0,1,0>",            -- Green color for money
      "Points System"           -- Source of notification
  )
  print(string.format("[SERVER POINTS] Point transfer alert sent to %s: %d points from %s",
                      recipient, points, sender))
end

local function OnClientCommand(module, command, player, args)
  if module == "ServerAlert" and command == "sendAlert" then
      -- Original alert functionality
      SendAlertPointx(args.targetPlayer, args.message, args.color, args.username)
  elseif module == "ServerPoints" and command == "notifyTransfer" then
      -- Handle point transfer notifications
      SendPointTransferAlert(args.recipient, args.sender, args.points)
  end
end

Events.OnClientCommand.Add(OnClientCommand)