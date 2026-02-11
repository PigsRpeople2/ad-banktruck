

local activeHeist = false

local target

RegisterNetEvent('ad-banktruck:start')
AddEventHandler('ad-banktruck:start', function()
    if activeHeist then
        return "Failed: Heist already active"
    else
        activeHeist = true
        RequestModel(GetHashKey(Config.truckModel))
        while not HasModelLoaded(GetHashKey(Config.truckModel)) do
            Wait(10)
        end
        local spawnLocation = Config.truckLocations[math.random(#Config.truckLocations)]
        local truck = CreateVehicle(GetHashKey(Config.truckModel), spawnLocation.x, spawnLocation.y, spawnLocation.z, spawnLocation.w, true, false)
        local blip = AddBlipForEntity(truck)
        SetVehicleDoorsLocked(truck, 4)
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

        local guards = {}
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

        function PlantC4()
            TaskStartScenarioInPlace(PlayerPedId(), "CODE_HUMAN_MEDIC_TEND_TO_KNEEL", 0, true)
            if lib.progressBar({
                duration = Config.C4PlantDuration,
                items = Config.C4Item,
                label = "Planting C4...",
                useWhileDead = false,
                canCancel = true,
                disable = {
                    move = true,
                    car = true,
                    combat = true,
                    mouse = false
                },
            }) then
                print("C4 planted successfully")
                local effectPos = (GetWorldPositionOfEntityBone(truck, GetEntityBoneIndexByName(truck, "door_dside_r")) + GetWorldPositionOfEntityBone(truck, GetEntityBoneIndexByName(truck, "door_pside_r"))) / 2
                ClearPedTasks(PlayerPedId())
                TriggerServerEvent('ad-banktruck:plantC4', NetworkGetNetworkIdFromEntity(truck))
                StartParticleFxLoopedAtCoord(
                    "proj_flare_trail" --[[ string ]], 
                    effectPos.x --[[ number ]], 
                    effectPos.y --[[ number ]], 
                    effectPos.z --[[ number ]], 
                    0 --[[ number ]], 
                    0 --[[ number ]], 
                    0 --[[ number ]], 
                    1.0 --[[ number ]], 
                    true --[[ boolean ]], 
                    true --[[ boolean ]], 
                    true --[[ boolean ]], 
                    false --[[ boolean ]]
                )
            else
                ClearPedTasks(PlayerPedId())
            end
        end


        target = exports.ox_target:addModel(`stockade`, {
            {
                name = 'stockade_rear_vault',
                icon = 'fas fa-lock',
                label = 'Open Doors',
                bones = {'door_dside_r', 'door_pside_r'}, 
                canInteract = function(entity, distance, coords, name, bone)
                    return GetEntitySpeed(entity) < 3.0 -- Can't interact with moving stockade
                end,
                onSelect = PlantC4()
                
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

        AddEventHandler('onResourceStop', function(resourceName)
            DeleteVehicle(truck)
            RemoveBlip(blip)
            for _, guard in ipairs(guards) do
                if DoesEntityExist(guard) then
                    DeleteEntity(guard)
                end
            end
        end)

    end
end)


RegisterNetEvent('ad-banktruck:plantC4')
AddEventHandler('ad-banktruck:plantC4', function(truckNetId)
    local truck = NetworkGetEntityFromNetworkId(truckNetId)
    if DoesEntityExist(truck) then -- Lock the doors to prevent further interaction
        exports.ox_target:removeModel(`stockade`)
    end
    
end)


RegisterCommand("run", function()
    TriggerServerEvent('ad-banktruck:startserver') -- For testing purposes, this command will trigger the server event to start the heist
end, false)