local activeHeist = false

RegisterNetEvent('ad-banktruck:startserver')
AddEventHandler('ad-banktruck:startserver', function()
    if not activeHeist then
        activeHeist = true
        TriggerClientEvent('ad-banktruck:start', -1)
    end
end)


RegisterNetEvent('ad-banktruck:C4')
AddEventHandler('ad-banktruck:C4', function()
    if activeHeist then
        TriggerClientEvent('ad-banktruck:plantC4', -1)
    end
end)


