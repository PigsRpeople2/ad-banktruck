local activeHeist = false
local heistCooldown = false

RegisterServerEvent('ad-banktruck:startserver')
AddEventHandler('ad-banktruck:startserver', function()
    if not activeHeist then
        if not heistCooldown then
            if exports.ox_inventory:GetItemCount(source, Config.startItem) >= Config.startItemAmount then
                if Config.consumeItem then
                    exports.ox_inventory:RemoveItem(source, Config.startItem, Config.startItemAmount)
                end
                TriggerClientEvent('ad-banktruck:start', -1)
                CreateThread(function()
                    Wait(Config.heistTimeout)
                    activeHeist = false
                    TriggerClientEvent('ad-banktruck:clear', -1)
                    heistCooldown = true
                    Wait(Config.heistCooldown)
                    heistCooldown = false
                end)
            else
                local itemLabel = exports.ox_inventory:Items(Config.startItem) and exports.ox_inventory:Items(Config.startItem).label or Config.startItem
                TriggerClientEvent('ox_lib:notify', source, {
                    type = 'error',
                    title = 'Missing Item',
                    description = 'You need at least ' .. Config.startItemAmount .. ' ' .. itemLabel .. ' to start the heist.',
                    position = 'top',
                })
            end
        else
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                title = 'Heist Cooldown',
                description = 'Please wait before starting another heist.',
                position = 'top',
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            title = 'Heist already in Progress',
            description = 'A heist is already in progress. Please wait for it to finish before starting another one.',
            position = 'top',
        })
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

