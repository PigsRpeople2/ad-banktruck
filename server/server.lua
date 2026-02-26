local activeHeist = false
local heistCooldown = false
local truck
local ped = nil
local cooledDown = false

local function getPoliceCount()
    if Config.policeScript == 'wasabi_police' then
        return exports['wasabi_police']:GetPoliceCount()
    end
    return 0
end

local function notify(src, type, title, desc)
    TriggerClientEvent('ox_lib:notify', src, {
        type = type,
        title = title,
        description = desc,
        position = 'top',
    })
end

RegisterServerEvent('ad-banktruck:startserver')
AddEventHandler('ad-banktruck:startserver', function()
    local src = source
    local police = getPoliceCount()

    if Config.policeRequired > 0 and police < Config.policeRequired then
        return notify(src, 'error', 'Not Enough Police', 'There must be at least ' .. Config.policeRequired .. ' police officers online.')
    end


    if activeHeist then
        return notify(src, 'error', 'Heist Active', 'A heist is already in progress.')
    end

    if heistCooldown then
        return notify(src, 'error', 'Cooldown', 'Please wait before starting another heist.')
    end

    local itemCount = exports.ox_inventory:GetItemCount(src, Config.startItem)
    if itemCount < Config.startItemAmount then
        local itemLabel = exports.ox_inventory:Items(Config.startItem)?.label or Config.startItem
        return notify(src, 'error', 'Missing Item', 'You need ' .. Config.startItemAmount .. 'x ' .. itemLabel)
    end

    if Config.consumeItem then
        exports.ox_inventory:RemoveItem(src, Config.startItem, Config.startItemAmount)
    end

    if Config.initialNotif then
        Config.initialPoliceDispatchExport()
    end

    local spawnLocation = Config.truckLocations[math.random(#Config.truckLocations)]
    truck = CreateVehicle(GetHashKey(Config.truckModel), spawnLocation.x, spawnLocation.y, spawnLocation.z - 0.5, spawnLocation.w, true, true)
    
    while not DoesEntityExist(truck) do Wait(0) end
    local netId = NetworkGetNetworkIdFromEntity(truck)

    cooledDown = false
    activeHeist = true
    
    TriggerClientEvent('ad-banktruck:start', -1, spawnLocation, netId)
    notify(src, 'success', 'Heist Started', 'Find the truck and plant C4 on the rear doors!')

    CreateThread(function()
        Wait(Config.heistTimeout)
        if activeHeist then
            activeHeist = false
            TriggerClientEvent('ad-banktruck:clear', -1, netId)
            if DoesEntityExist(truck) then DeleteEntity(truck) end
            
            if not cooledDown then
                heistCooldown = true
                Wait(Config.heistCooldown)
                heistCooldown = false
                cooledDown = true
            end
        end
    end)

    if not Config.universalBlips then
        Wait(200)
        TriggerClientEvent('ad-banktruck:makeBlip', src, netId)
    end
end)

RegisterNetEvent('ad-banktruck:server:spawnGuards', function(spawnLocation)
    local src = source
    local guardNetIds = {}

    for i = 1, Config.guards do
        local offset = Config.guardPositions[i]
        
        local headingRad = math.rad(spawnLocation.w)
        local cosH = math.cos(headingRad)
        local sinH = math.sin(headingRad)

        local offsetX = offset.x * cosH - offset.y * sinH
        local offsetY = offset.x * sinH + offset.y * cosH
        
        local spawnPos = vector3(spawnLocation.x + offsetX, spawnLocation.y + offsetY, spawnLocation.z + offset.z)
        
        local guard = CreatePed(4, GetHashKey(Config.guardModel), spawnPos.x, spawnPos.y, spawnPos.z, spawnLocation.w, true, true)
        
        local timeout = 0
        while not DoesEntityExist(guard) and timeout < 100 do
            Wait(10)
            timeout = timeout + 1
        end

        if DoesEntityExist(guard) then
            local netId = NetworkGetNetworkIdFromEntity(guard)
            table.insert(guardNetIds, netId)
        end
    end

    TriggerClientEvent('ad-banktruck:client:setupGuards', src, guardNetIds)
end)

RegisterNetEvent('ad-banktruck:server:startHeist', function(spawnCoords, truckNetId)
    local guardNetIds = {}
    local guardModel = GetHashKey(Config.guardModel)

    for i = 1, Config.guards do
        local offset = Config.guardPositions[i]
        
        local headingRad = math.rad(spawnCoords.w)
        local cosShape = math.cos(headingRad)
        local sinShape = math.sin(headingRad)

        local spawnX = spawnCoords.x + (offset.x * cosShape - offset.y * sinShape)
        local spawnY = spawnCoords.y + (offset.x * sinShape + offset.y * cosShape)
        local spawnZ = spawnCoords.z + offset.z

        local ped = CreatePed(4, guardModel, spawnX, spawnY, spawnZ, spawnCoords.w, true, true)
        
        local timeout = 0
        while not DoesEntityExist(ped) and timeout < 100 do 
            Wait(10) 
            timeout = timeout + 1
        end
        
        if DoesEntityExist(ped) then
            local netId = NetworkGetNetworkIdFromEntity(ped)
            Entity(ped).state.isBankGuard = true 
            table.insert(guardNetIds, netId)
        end
    end

    TriggerClientEvent('ad-banktruck:start', -1, spawnCoords, truckNetId, guardNetIds)
end)

RegisterServerEvent('ad-banktruck:plantC4')
AddEventHandler('ad-banktruck:plantC4', function(truckNetId, activePlayers)
    local src = source
    if not activeHeist then return end

    local truckEnt = NetworkGetEntityFromNetworkId(truckNetId)
    if not DoesEntityExist(truckEnt) then return end

    local pPed = GetPlayerPed(src)
    if #(GetEntityCoords(pPed) - GetEntityCoords(truckEnt)) > 10.0 then
        return
    end

    if exports.ox_inventory:GetItemCount(src, Config.C4Item) > 0 then
        exports.ox_inventory:RemoveItem(src, Config.C4Item, 1)

        TriggerClientEvent('ad-banktruck:createC4', -1, truckNetId)
        for _, serverId in ipairs(activePlayers) do
            TriggerClientEvent('ad-banktruck:syncC4Ptfx', serverId, truckNetId)
        end

        SetTimeout(Config.C4DetonateDuration, function()
            if activeHeist and DoesEntityExist(truckEnt) then
                
                Entity(truckEnt).state:set('isExploded', true, true)

                TriggerClientEvent('ad-banktruck:detonateC4', -1, truckNetId)
                
            end
        end)
    end
end)

RegisterServerEvent('ad-banktruck:grabMoney')
AddEventHandler('ad-banktruck:grabMoney', function(truckNetId)
    local src = source 
    if not activeHeist then return end

    local truckEnt = NetworkGetEntityFromNetworkId(truckNetId)
    if not DoesEntityExist(truckEnt) then return end
    if Entity(truckEnt).state.isLooted then 
        return TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'The truck is empty!'}) 
    end

    local pPed = GetPlayerPed(src)
    if #(GetEntityCoords(pPed) - GetEntityCoords(truckEnt)) < 10.0 then
        Entity(truckEnt).state:set('isLooted', true, true)
        TriggerClientEvent('ad-banktruck:updateProps', -1)

        for _, reward in ipairs(Config.rewards) do
            if math.random(1, 100) <= reward.chance then
                local amount = math.random(reward.range.min, reward.range.max)
                exports.ox_inventory:AddItem(src, reward.item, amount)
            end
        end
        
        activeHeist = false
        
        if Config.heistPersist then
            SetTimeout(Config.heistPersistTime, function()
                TriggerClientEvent('ad-banktruck:clear', -1, truckNetId)
                if DoesEntityExist(truckEnt) then DeleteEntity(truckEnt) end
            end)
        end
        
        heistCooldown = true
        SetTimeout(Config.heistCooldown, function()
            heistCooldown = false
        end)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if truck and DoesEntityExist(truck) then DeleteEntity(truck) end
        if ped and DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)
