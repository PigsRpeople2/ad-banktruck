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





RegisterNetEvent('ad-banktruck:grabMoney')
AddEventHandler('ad-banktruck:grabMoney', function()
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
            DeleteObject(scatterProp)
            for i = 1, #props do
                local prop = props[i]
                if DoesEntityExist(prop) then
                    DeleteObject(prop)
                end
            end
            RemoveBlip(blip)
        else
            ClearPedTasks(PlayerPedId())
        end

    end
end)

RegisterNetEvent('ad-banktruck:detonateC4')
AddEventHandler('ad-banktruck:detonateC4', function(truckNetId)
    local truckEntity = NetworkGetEntityFromNetworkId(truckNetId)
    if truckEntity == truck then
        if DoesEntityExist(truck) then
            StopParticleFxLooped(ptfxHandle, false)

            local effectPos = (GetWorldPositionOfEntityBone(truck, GetEntityBoneIndexByName(truck, "door_dside_r")) + GetWorldPositionOfEntityBone(truck, GetEntityBoneIndexByName(truck, "door_pside_r"))) / 2

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
                onSelect = function ()
                    TriggerEvent('ad-banktruck:grabMoney')
                end
            }
        })
        end
    end
end)



RegisterNetEvent('ad-banktruck:plantC4')
AddEventHandler('ad-banktruck:createC4', function(...)
    print("does exist?")
    print(truck)
    if DoesEntityExist(truck) then -- Lock the doors to prevent further interaction
        print("creating C4 effect")
        exports.ox_target:removeModel(`stockade`)
        local effectPos = (GetWorldPositionOfEntityBone(truck, GetEntityBoneIndexByName(truck, "door_dside_r")) + GetWorldPositionOfEntityBone(truck, GetEntityBoneIndexByName(truck, "door_pside_r"))) / 2
        print("starting effect")
        
        local guardTeamHash = GetHashKey('PLAYER_PHOBIC')
        if not Config.guardHostile then
            SetRelationshipBetweenGroups(5, guardTeamHash, `PLAYER`)
            SetRelationshipBetweenGroups(5, `PLAYER`, guardTeamHash)
        end
        
        if not HasNamedPtfxAssetLoaded(ptfxAssetName) then
            RequestNamedPtfxAsset(ptfxAssetName)
            while not HasNamedPtfxAssetLoaded(ptfxAssetName) do
                Wait(10) -- Wait briefly to prevent the script from halting the server
            end
            print("ptfx asset loaded")
        else
            print("ptfx asset already loaded")
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


local function plantC4(truck)
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
                move = true,
                car = true,
                combat = true,
                mouse = false
            },
        }) then
            TriggerEvent('ad-banktruck:createC4', NetworkGetNetworkIdFromEntity(truck))
            TriggerServerEvent('ad-banktruck:plantC4', NetworkGetNetworkIdFromEntity(truck))
        else
            ClearPedTasks(PlayerPedId())
        end
    else
        lib.notify(
            {
                title = "Bank Truck Heist",
                description = "You don't have any C4 to plant! Find some and try again.",
                type = "error",
                position = "top"
            }
        )
    end
end



RegisterNetEvent('ad-banktruck:start')
AddEventHandler('ad-banktruck:start', function()
    if activeHeist then
        lib.notify(
            {
                title = "Bank Truck Heist",
                description = "A heist is already active! Wait for it to finish before starting another.",
                type = "error",
                position = "top"
            }
        )
        return "Failed: Heist already active"
    else
        activeHeist = true
        RequestModel(GetHashKey(Config.truckModel))
        while not HasModelLoaded(GetHashKey(Config.truckModel)) do
            Wait(10)
        end
        local spawnLocation = Config.truckLocations[math.random(#Config.truckLocations)] - vec4(0.0, 0.0, 0.5, 0.0)
        truck = CreateVehicle(GetHashKey(Config.truckModel), spawnLocation.x, spawnLocation.y, spawnLocation.z, spawnLocation.w, true, false)
        SetEntityInvincible(truck, true)
        FreezeEntityPosition(truck, true)
        blip = AddBlipForEntity(truck)
        SetVehicleDoorsLocked(truck, 10)
        SetBlipSprite(blip, 477) -- Set blip to a truck icon
        SetBlipColour(blip, 1) -- Set blip color to red
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Bank Truck")
        EndTextCommandSetBlipName(blip)



        if not HasModelLoaded(GetHashKey(propName)) then
            RequestModel(GetHashKey(propName))
            while not HasModelLoaded(GetHashKey(propName)) do
                Wait(10)
            end
        end

        local centralBonePos = GetWorldPositionOfEntityBone(truck, GetEntityBoneIndexByName(truck, "seat_dside_f"))
        for i = 1, #bagOffsets do
            
            local propPos = GetOffsetFromCoordAndHeadingInWorldCoords(centralBonePos.x, centralBonePos.y, centralBonePos.z, spawnLocation.w, bagOffsets[i].x, bagOffsets[i].y, bagOffsets[i].z)
            local propPosRand = vector3(propPos.x + math.random(-10, 10) * 0.001, propPos.y + math.random(-5, 5) * 0.01, propPos.z)
            if math.random(1, 10) ~= 1 then
                propPos = vector3(propPos.x, propPos.y, propPos.z - 0.1)
                local prop = CreateObject(GetHashKey(propName), propPosRand.x, propPosRand.y, propPosRand.z, true, true, false)
                local bagRot = 90 + math.random(-10, 10)
                SetEntityHeading(prop, spawnLocation.w + bagRot)
                SetEntityCollision(prop, false, false)
                table.insert(props, prop)
            end
        end

        if not HasModelLoaded(GetHashKey(scatterPropName)) then
            RequestModel(GetHashKey(scatterPropName))
            while not HasModelLoaded(GetHashKey(scatterPropName)) do
                Wait(10)
            end
        end

        local scatterPropPos = GetOffsetFromCoordAndHeadingInWorldCoords(centralBonePos.x, centralBonePos.y, centralBonePos.z, spawnLocation.w, 0.675, -2.8, -0.5)
        scatterProp = CreateObject(GetHashKey(scatterPropName), scatterPropPos.x, scatterPropPos.y, scatterPropPos.z, true, true, false)
        SetEntityHeading(scatterProp, spawnLocation.w + 270)
        SetEntityCollision(scatterProp, false, false)


        if not HasModelLoaded(GetHashKey(Config.guardModel)) then
            RequestModel(GetHashKey(Config.guardModel))
            while not HasModelLoaded(GetHashKey(Config.guardModel)) do
                Wait(10)
            end
        end

        AddRelationshipGroup('PLAYER_PHOBIC')
        local guardTeamHash = GetHashKey('PLAYER_PHOBIC')
        SetRelationshipBetweenGroups(0, guardTeamHash, guardTeamHash)
        if Config.guardHostile then
            SetRelationshipBetweenGroups(5, guardTeamHash, `PLAYER`)
            SetRelationshipBetweenGroups(5, `PLAYER`, guardTeamHash)
        else
            SetRelationshipBetweenGroups(4, guardTeamHash, `PLAYER`)
            SetRelationshipBetweenGroups(4, `PLAYER`, guardTeamHash)
        end

        for i = 1, Config.guards do
            local guardPos = GetOffsetFromCoordAndHeadingInWorldCoords(spawnLocation.x, spawnLocation.y, spawnLocation.z, spawnLocation.w, Config.guardPositions[i].x, Config.guardPositions[i].y, Config.guardPositions[i].z)
            local guard = CreatePed(4, GetHashKey(Config.guardModel), guardPos.x, guardPos.y, guardPos.z, 0.0, true, false)
            table.insert(guards, guard)
            GiveWeaponToPed(guard, GetHashKey(Config.guardWeapon), -1, false, true)
            SetPedCombatAttributes(guard, 46, true)
            if Config.guardHostile then
                TaskCombatPed(guard, PlayerPedId(), 0, 16)
            end
            SetPedRelationshipGroupHash(guard, guardTeamHash)
        end

        lib.notify(
            {
                title = "Bank Truck Heist",
                description = "A bank truck has spawned! Find it and plant C4 on the rear doors!",
                type = "success",
                position = "top"
            }
        )


        exports.ox_target:addModel(`stockade`, {
            {
                name = 'stockade_rear_vault',
                item = Config.C4Item,
                icon = 'fas fa-lock',
                label = 'Plant C4',
                bones = {'door_dside_r', 'door_pside_r'}, 
                canInteract = function(entity, distance, coords, name, bone)
                    return GetEntitySpeed(entity) < 3.0 -- Can't interact with moving stockade
                end,
                onSelect = function ()
                    plantC4(truck)
                end
            }
        })


        Citizen.CreateThread(function()
            while activeHeist do
                if not DoesEntityExist(truck) then
                    activeHeist = false
                    RemoveBlip(blip)
                    for _, guard in ipairs(guards) do
                        if DoesEntityExist(guard) then
                            DeleteEntity(guard)
                        end
                    end
                    break
                end
                Wait(1000)
            end
        end)

        

    end
end)





RegisterCommand("run", function()
    TriggerServerEvent('ad-banktruck:startserver') -- For testing purposes, this command will trigger the server event to start the heist
end, false)

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
            content = "This heist is currently disabled. Please check back later.",
            centered = true,
            cancel = false
        })
    end
end)

if not DoesEntityExist(ped) then
    local modelHash = GetHashKey(Config.pedModel)
    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(10)
        end
    end
    ped = CreatePed(
		0 --[[ integer ]], 
		modelHash --[[ Hash ]], 
		Config.pedLocation.x --[[ number ]], 
		Config.pedLocation.y --[[ number ]], 
		Config.pedLocation.z --[[ number ]], 
		Config.pedLocation.w --[[ number ]], 
		true --[[ boolean ]], 
		true --[[ boolean ]]
	)

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports.ox_target:addEntity(NetworkGetNetworkIdFromEntity(ped), {
        {
            name = 'start_banktruck_heist',
            icon = 'fas fa-truck',
            distance = 2.0,
            label = 'Start Bank Truck Heist',
            onSelect = function()
                TriggerEvent('ad-banktruck:startDialog')
            end
        }
    })
end


RegisterNetEvent('ad-banktruck:clear')
AddEventHandler('ad-banktruck:clear', function()
    if DoesEntityExist(truck) then
        DeleteVehicle(truck)
    end
    RemoveBlip(blip)
    for _, guard in ipairs(guards) do
        if DoesEntityExist(guard) then
            DeleteEntity(guard)
        end
    end
    StopParticleFxLooped(ptfxHandle, false)
    for _, prop in ipairs(props) do
        if DoesEntityExist(prop) then
            DeleteObject(prop)
        end
    end
    if DoesEntityExist(scatterProp) then
        DeleteObject(scatterProp)
    end
    activeHeist = false
end)

AddEventHandler('onResourceStop', function(resourceName)
    DeleteVehicle(truck)
    RemoveBlip(blip)
    for _, guard in ipairs(guards) do
        if DoesEntityExist(guard) then
            DeleteEntity(guard)
        end
    end
    StopParticleFxLooped(ptfxHandle, false)
    for _, prop in ipairs(props) do
        if DoesEntityExist(prop) then
            DeleteObject(prop)
        end
    end
    if DoesEntityExist(scatterProp) then
        DeleteObject(scatterProp)
    end
    if DoesEntityExist(ped) then
        DeleteEntity(ped)
    end
end)