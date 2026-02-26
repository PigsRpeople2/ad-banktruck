local activeHeist = false
local truck
local ptfxAssetName = "core"
local effectSpawn = "proj_flare_trail"
local ptfxHandle
local blip
local guards = {}
local props = {}
local propName = "prop_money_bag_01" --ex_prop_crate_money_sc   prop_money_bag_01 bkr_prop_bkr_cashpile_07
local scatterProp
local scatterPropName = "ex_cash_scatter_01"
local ped
local startZone = nil
local startCoords
local spawnZone
local spawnedGuards = false

local function GetActivePlayersServerId()
    local activePlayers = {}
    for _, v in ipairs(GetActivePlayers()) do
        table.insert(activePlayers, GetPlayerServerId(v))
    end
    return activePlayers
end

local bagOffsets = {
    vector3(1.625, -2.0, -0.2),
    vector3(1.625, -2.4, -0.2),
    vector3(1.625, -2.8, -0.2),
    vector3(1.625, -3.2, -0.2),
    vector3(1.625, -3.6, -0.2),
    vector3(1.625, -4.0, -0.2),
    vector3(-0.275, -2.0, -0.2),
    vector3(-0.275, -2.4, -0.2),
    vector3(-0.275, -2.8, -0.2),
    vector3(-0.275, -3.2, -0.2),
    vector3(-0.275, -3.6, -0.2),
    vector3(-0.275, -4.0, -0.2),
}



local ped = nil
local modelHash = GetHashKey(Config.pedModel)

local point = lib.points.new({
    coords = vector3(Config.pedLocation.x, Config.pedLocation.y, Config.pedLocation.z),
    distance = 50, 
})

function point:onEnter()
    lib.requestModel(modelHash, 500) 
    ped = CreatePed(0, modelHash, Config.pedLocation.x, Config.pedLocation.y, Config.pedLocation.z, Config.pedLocation.w, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)
    SetModelAsNoLongerNeeded(modelHash)

    startZone = exports.ox_target:addSphereZone({
    coords = vector3(Config.pedLocation.x, Config.pedLocation.y, Config.pedLocation.z),
    radius = 2.5,
    options = {
        name = 'start_banktruck_heist',
        icon = 'fas fa-truck',
        label = 'Start Bank Truck Heist',
        distance = 2.5,
        onSelect = function()
            TriggerEvent('ad-banktruck:startDialog')
        end,
    }
})
end

function point:onExit()
    if DoesEntityExist(ped) then
        DeleteEntity(ped)
        ped = nil
    end
    if startZone then exports.ox_target:removeZone(startZone) startZone = nil end
end

RegisterNetEvent('ad-banktruck:grabMoney')
AddEventHandler('ad-banktruck:grabMoney', function(truckEntity)
    if DoesEntityExist(truckEntity) then
        truck = truckEntity
    end

    if DoesEntityExist(truck) then
        if lib.progressBar({
            duration = Config.C4PlantDuration,
            items = Config.C4Item,
            label = "Grabbing Money...",
            useWhileDead = false,
            canCancel = true,
            anim = {
                clip = "grab",
                dict = "anim@scripted@player@mission@tun_table_grab@gold@heeled@"
            },
            disable = {
                move = true,
                car = true,
                combat = true,
                mouse = false
            },
        }) then
            exports.ox_target:removeModel(`stockade`)
            TriggerServerEvent('ad-banktruck:grabMoney', NetworkGetNetworkIdFromEntity(truck))

            if DoesEntityExist(scatterProp) then DeleteObject(scatterProp) end
            for i = 1, #props do
                if DoesEntityExist(props[i]) then
                    DeleteObject(props[i])
                end
            end
            if blip then RemoveBlip(blip) end
        else
            ClearPedTasks(PlayerPedId())
        end
    end
end)

RegisterNetEvent('ad-banktruck:detonateC4')
AddEventHandler('ad-banktruck:detonateC4', function(truckEntity)
    if DoesEntityExist(truckEntity) then
        truck = truckEntity
    end

    if DoesEntityExist(truck) then
        StopParticleFxLooped(ptfxHandle, false)

        local dside = GetWorldPositionOfEntityBone(truck, GetEntityBoneIndexByName(truck, "door_dside_r"))
        local pside = GetWorldPositionOfEntityBone(truck, GetEntityBoneIndexByName(truck, "door_pside_r"))
        local effectPos = (dside + pside) / 2

        AddExplosion(effectPos.x, effectPos.y, effectPos.z, 5, 5.0, true, false, 1.0)
        SetVehicleDoorOpen(truck, 2, false, false)
        SetVehicleDoorOpen(truck, 3, false, false)

        exports.ox_target:addModel(`stockade`, {
            {
                name = 'stockade_rear_vault',
                icon = 'fas fa-lock',
                label = 'Take Money',
                bones = {'door_dside_r', 'door_pside_r'},
                canInteract = function(entity, distance, coords, name, bone)
                    return GetEntitySpeed(entity) < 3.0 -- Can't interact with moving stockade
                end,
                onSelect = function()
                    TriggerEvent('ad-banktruck:grabMoney', truck)
                end
            }
        })
    end
end)

RegisterNetEvent('ad-banktruck:createC4')
AddEventHandler('ad-banktruck:createC4', function(truckNetId)
    local truckEntity = NetworkGetEntityFromNetworkId(truckNetId)
    if DoesEntityExist(truckEntity) then
        truck = truckEntity
    end

    if DoesEntityExist(truck) then -- Lock the doors to prevent further interaction
        exports.ox_target:removeModel(`stockade`)

        local guardTeamHash = GetHashKey('PLAYER_PHOBIC')
        if not Config.guardHostile then
            SetRelationshipBetweenGroups(5, guardTeamHash, `PLAYER`)
            SetRelationshipBetweenGroups(5, `PLAYER`, guardTeamHash)
        end
    end
end)

RegisterNetEvent('ad-banktruck:syncC4Ptfx')
AddEventHandler('ad-banktruck:syncC4Ptfx', function(truckNetId)
    local truckEntity = NetworkGetEntityFromNetworkId(truckNetId)
    if DoesEntityExist(truckEntity) then
        truck = truckEntity
    end

    if DoesEntityExist(truck) then
        local dside = GetWorldPositionOfEntityBone(truck, GetEntityBoneIndexByName(truck, "door_dside_r"))
        local pside = GetWorldPositionOfEntityBone(truck, GetEntityBoneIndexByName(truck, "door_pside_r"))
        local effectPos = (dside + pside) / 2

        if not HasNamedPtfxAssetLoaded(ptfxAssetName) then
            RequestNamedPtfxAsset(ptfxAssetName)
            while not HasNamedPtfxAssetLoaded(ptfxAssetName) do
                Wait(0)
            end
        end

        UseParticleFxAssetNextCall(ptfxAssetName)
        ptfxHandle = StartParticleFxLoopedAtCoord(
            effectSpawn, -- Effect name
            effectPos.x, effectPos.y, effectPos.z - 0.75, -- Coordinates
            0.0, 0.0, 0.0, -- Rotation
            2.5, -- Scale
            false, false, false, -- Axis flags and a boolean
            false
        )
    end
end)

local function plantC4(truckEnt)
    if exports.ox_inventory:Search('count', Config.C4Item) > 0 then
        Config.policeDispatchExport()
    end
    if exports.ox_inventory:GetItemCount(Config.C4Item) > 0 then
        if lib.progressBar({
            duration = Config.C4PlantDuration,
            items = Config.C4Item,
            label = "Planting C4...",
            useWhileDead = false,
            canCancel = true,
            anim = {
                clip = "car_bomb_mechanic",
                dict = "mp_car_bomb"
            },
            disable = {
                move = true, car = true, combat = true, mouse = false
            },
        }) then
            local netId = NetworkGetNetworkIdFromEntity(truckEnt)
            TriggerServerEvent('ad-banktruck:plantC4', netId, GetActivePlayersServerId())
        else
            ClearPedTasks(PlayerPedId())
        end
    else
        lib.notify({
            title = "Bank Truck Heist",
            description = "You don't have any C4 to plant! Find some and try again.",
            type = "error",
            position = "top"
        })
    end
end

RegisterNetEvent('ad-banktruck:makeBlip')
AddEventHandler('ad-banktruck:makeBlip', function()
    print("made blip")

    if blip then RemoveBlip(blip) end
    blip = AddBlipForCoord(startCoords.x, startCoords.y, startCoords.z)
    SetBlipSprite(blip, 477) -- Set blip to a truck icon
    SetBlipColour(blip, 1) -- Set blip color to red
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Bank Truck")
    EndTextCommandSetBlipName(blip)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 1)
end)

RegisterNetEvent('ad-banktruck:start')
AddEventHandler('ad-banktruck:start', function(spawnLocation, netId)
    startCoords = spawnLocation
    if activeHeist then return end

    local timeout = 0
    while not NetworkDoesNetworkIdExist(netId) and timeout < 150 do
        Wait(100)
        timeout = timeout + 1
    end

    if not NetworkDoesNetworkIdExist(netId) then
        print("^1[ERROR] Bank Truck failed to sync via Network ID.^7")
        return
    end

    truck = NetToVeh(netId)

    if not DoesEntityExist(truck) then
        print("^1[ERROR] Local entity handle is invalid!^7")
        return
    end

    SetNetworkIdCanMigrate(netId, true)
    SetEntityAsMissionEntity(truck, true, true)
    activeHeist = true
    SetEntityInvincible(truck, true)
    FreezeEntityPosition(truck, true)

    if Config.universalBlips then
        print("created universal Blip")
        if blip then RemoveBlip(blip) end
        local bX, bY, bZ = spawnLocation.x, spawnLocation.y, spawnLocation.z
        blip = AddBlipForCoord(bX, bY, bZ)

        SetBlipSprite(blip, 477)
        SetBlipColour(blip, 1)
        SetBlipScale(blip, 1.0)
        SetBlipAsShortRange(blip, false)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Bank Truck")
        EndTextCommandSetBlipName(blip)
    end

    if not HasModelLoaded(GetHashKey(propName)) then
        RequestModel(GetHashKey(propName))
        while not HasModelLoaded(GetHashKey(propName)) do Wait(10) end
    end

    local centralBonePos = GetWorldPositionOfEntityBone(truck, GetEntityBoneIndexByName(truck, "seat_dside_f"))
    for i = 1, #bagOffsets do
        local propPos = GetOffsetFromCoordAndHeadingInWorldCoords(centralBonePos.x, centralBonePos.y, centralBonePos.z, spawnLocation.w, bagOffsets[i].x, bagOffsets[i].y, bagOffsets[i].z)
        local propPosRand = vector3(propPos.x + math.random(-10, 10) * 0.001, propPos.y + math.random(-5, 5) * 0.01, propPos.z)

        if math.random(1, 10) ~= 1 then
            local prop = CreateObject(GetHashKey(propName), propPosRand.x, propPosRand.y, propPosRand.z - 0.1, true, true, false)
            SetEntityHeading(prop, spawnLocation.w + 90 + math.random(-10, 10))
            SetEntityCollision(prop, false, false)
            table.insert(props, prop)
        end
    end

    if not HasModelLoaded(GetHashKey(scatterPropName)) then
        RequestModel(GetHashKey(scatterPropName))
        while not HasModelLoaded(GetHashKey(scatterPropName)) do Wait(10) end
    end

    local scatterPropPos = GetOffsetFromCoordAndHeadingInWorldCoords(centralBonePos.x, centralBonePos.y, centralBonePos.z, spawnLocation.w, 0.675, -2.8, -0.5)
    scatterProp = CreateObject(GetHashKey(scatterPropName), scatterPropPos.x, scatterPropPos.y, scatterPropPos.z, true, true, false)
    SetEntityHeading(scatterProp, spawnLocation.w + 270)
    SetEntityCollision(scatterProp, false, false)

    spawnZone = lib.zones.sphere({
        coords = vector3(spawnLocation.x, spawnLocation.y, spawnLocation.z),
        radius = 100.0,
        debugPoly = false,
        onEnter = function()
            if not spawnedGuards then
                TriggerServerEvent('ad-banktruck:server:spawnGuards', spawnLocation)
                spawnedGuards = true
            end
        end,
    })

    exports.ox_target:addModel(`stockade`, {
        {
            name = 'stockade_rear_vault',
            icon = 'fas fa-lock',
            label = 'Plant C4',
            bones = {'door_dside_r', 'door_pside_r'},
            canInteract = function(entity, distance, coords, name, bone)
                return GetEntitySpeed(entity) < 3.0
            end,
            onSelect = function()
                plantC4(truck)
            end
        }
    })

    CreateThread(function()
        Wait(5000)
        while activeHeist do
            Wait(3000)
            if not DoesEntityExist(truck) and NetworkDoesNetworkIdExist(netId) then
                local veh = NetToVeh(netId)
                if DoesEntityExist(veh) then
                    truck = veh
                    SetEntityAsMissionEntity(truck, true, true)
                end
            end
        end
    end)
end)

RegisterNetEvent('ad-banktruck:client:setupGuards', function(guardNetIds)
    AddRelationshipGroup('PLAYER_PHOBIC')
    local guardTeamHash = GetHashKey('PLAYER_PHOBIC')
    local relation = Config.guardHostile and 5 or 4
    SetRelationshipBetweenGroups(relation, guardTeamHash, `PLAYER`)
    SetRelationshipBetweenGroups(relation, `PLAYER`, guardTeamHash)

    for i = 1, #guardNetIds do
        local netId = guardNetIds[i]
        local timeout = 0

        while not NetworkDoesNetworkIdExist(netId) and timeout < 100 do
            Wait(100)
            timeout = timeout + 1
        end

        if NetworkDoesNetworkIdExist(netId) then
            local guard = NetToPed(netId)
            if DoesEntityExist(guard) then
                table.insert(guards, guard)

                SetNetworkIdCanMigrate(netId, true)
                SetEntityAsMissionEntity(guard, true, true)

                GiveWeaponToPed(guard, GetHashKey(Config.guardWeapon), -1, false, true)
                SetPedCombatAttributes(guard, 46, true)
                if Config.guardHostile then TaskCombatPed(guard, PlayerPedId(), 0, 16) end
                SetPedRelationshipGroupHash(guard, guardTeamHash)
            end
        end
    end
end)

RegisterNetEvent('ad-banktruck:startDialog')
AddEventHandler('ad-banktruck:startDialog', function()
    if Config.enabled then
        local alert = lib.alertDialog({
            header = "Bank Truck Heist",
            content = "Are you sure you want to start the heist? This will cost " .. Config.startItemAmount .. " " .. exports.ox_inventory:Items(Config.startItem).label,
            centered = true,
            cancel = true
        })
        if alert == "confirm" then
            TriggerServerEvent('ad-banktruck:startserver')
        end
    else
        lib.alertDialog({
            header = "Bank Truck Heist",
            content = "This heist is currently disabled.",
            centered = true,
            cancel = false
        })
    end
end)

RegisterNetEvent('ad-banktruck:updateProps')
AddEventHandler('ad-banktruck:updateProps', function()
    for _, prop in ipairs(props) do
        if DoesEntityExist(prop) then DeleteObject(prop) end
    end
    if DoesEntityExist(scatterProp) then DeleteObject(scatterProp) end
end)

RegisterNetEvent('ad-banktruck:clear')
AddEventHandler('ad-banktruck:clear', function(truckEntity)
    if DoesEntityExist(truckEntity) then DeleteVehicle(truckEntity) end
    if DoesEntityExist(truck) then DeleteVehicle(truck) end
    if blip then RemoveBlip(blip) end
    for _, guard in ipairs(guards) do
        if DoesEntityExist(guard) then DeleteEntity(guard) end
    end
    spawnedGuards = false
    StopParticleFxLooped(ptfxHandle, false)
    for _, prop in ipairs(props) do
        if DoesEntityExist(prop) then DeleteObject(prop) end
    end
    if DoesEntityExist(scatterProp) then DeleteObject(scatterProp) end
    activeHeist = false
end)


AddEventHandler('onResourceStop', function(resourceName)
    if startZone then exports.ox_target:removeZone(startZone) end
    if GetCurrentResourceName() ~= resourceName then return end
    if blip then RemoveBlip(blip) end
    for _, guard in ipairs(guards) do
        if DoesEntityExist(guard) then DeleteEntity(guard) end
    end
    StopParticleFxLooped(ptfxHandle, false)
    for _, prop in ipairs(props) do
        if DoesEntityExist(prop) then DeleteObject(prop) end
    end
    if DoesEntityExist(scatterProp) then DeleteObject(scatterProp) end
    if DoesEntityExist(ped) then DeleteEntity(ped) end
    spawnedGuards = false
end)