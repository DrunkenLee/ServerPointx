require "ServerPointsShared"

ServerTraitHandler = {}

function ServerTraitHandler.processQueue()
    -- Ensure the queue is initialized
    ServerPointsShared.QueueTrait = ServerPointsShared.QueueTrait or {}

    for i, queueObj in ipairs(ServerPointsShared.QueueTrait) do
        local player = getPlayerFromUsername(queueObj.username)
        if player then
            if queueObj.remove then
                if player:HasTrait(queueObj.trait) then
                    player:getTraits():remove(queueObj.trait)
                    player:Say("Trait removed: " .. queueObj.trait)
                end
            else
                if not player:HasTrait(queueObj.trait) then
                    player:getTraits():add(queueObj.trait)
                    player:Say("Trait added: " .. queueObj.trait)
                end
            end
        end
    end
    -- Clear the queue after processing
    ServerPointsShared.QueueTrait = {}
end

Events.EveryTenMinutes.Add(ServerTraitHandler.processQueue)

return ServerTraitHandler