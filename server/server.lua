local activeHeist = false

RegisterServerEvent('ad-banktruck:startserver')
AddEventHandler('ad-banktruck:startserver', function()
    if not activeHeist then
        activeHeist = true
        TriggerClientEvent('ad-banktruck:start', -1)
    end
end)


RegisterServerEvent('ad-banktruck:grabMoney')
AddEventHandler('ad-banktruck:grabMoney', function(truckNetId, player)
    if activeHeist then
        local truck = NetworkGetEntityFromNetworkId(truckNetId)
        if DoesEntityExist(truck) then      
            local player = source
            local ped = GetPlayerPed(player)
            local playerCoords = GetEntityCoords(ped)
            local truckCoords = GetEntityCoords(truck)
            if ((playerCoords.x - truckCoords.x)^2 + (playerCoords.y - truckCoords.y)^2 + (playerCoords.z - truckCoords.z)^2) < 25.0 then
                for _, reward in ipairs(Config.rewards) do
                    if math.random(1, 100) <= reward.chance then
                        local amount = math.random(reward.range.min, reward.range.max)
                        exports.ox_inventory:AddItem(player, reward.item, amount)
                    end
                end
            end
        end
    end
end)


RegisterServerEvent('ad-banktruck:plantC4')
AddEventHandler('ad-banktruck:plantC4', function(truckNetId)
    print("C4 planted on truck with ID: " .. tostring(truckNetId))
    if activeHeist then
        if exports.ox_inventory:GetItemCount(source, Config.C4Item) > 0 then
            exports.ox_inventory:RemoveItem(source, Config.C4Item, 1)
            
            Wait(Config.C4DetonateDuration)

            TriggerClientEvent('ad-banktruck:detonateC4', -1, truckNetId)

        else
            print("Player does not have any " .. Config.C4Item .. " to plant!")
        end
    end
end)


