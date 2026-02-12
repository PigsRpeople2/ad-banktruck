local activeHeist = false

RegisterServerEvent('ad-banktruck:startserver')
AddEventHandler('ad-banktruck:startserver', function()
    if not activeHeist then
        activeHeist = true
        TriggerClientEvent('ad-banktruck:start', -1)
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


