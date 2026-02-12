local activeHeist = false
local truck
local ptfxAssetName = "core"
local effectSpawn = "proj_flare_trail"
local ptfxHandle
local blip
local guards = {}


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
        local spawnLocation = Config.truckLocations[math.random(#Config.truckLocations)]
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

        RequestModel(GetHashKey(Config.guardModel))
        while not HasModelLoaded(GetHashKey(Config.guardModel)) do
            Wait(10)
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
            local guard = CreatePed(4, GetHashKey(Config.guardModel), spawnLocation.x + Config.guardPositions[i].x, spawnLocation.y + Config.guardPositions[i].y, spawnLocation.z + Config.guardPositions[i].z, 0.0, true, false)
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
                label = 'Open Doors',
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



AddEventHandler('onResourceStop', function(resourceName)
    DeleteVehicle(truck)
    RemoveBlip(blip)
    for _, guard in ipairs(guards) do
        if DoesEntityExist(guard) then
            DeleteEntity(guard)
        end
    end
    StopParticleFxLooped(ptfxHandle, false)
end)