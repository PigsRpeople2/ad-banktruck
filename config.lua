Config = {}

Config.enabled = true -- Whether the heist is enabled or not, can be used to disable the heist without removing the script
Config.policeRequired = 3 -- The required amount of police online to start the heist, set to 0 to not require any police
Config.framework = "qbox"

Config.pedLocation = vec4(934.6655, -1520.6864, 30.0653, 320.7801) -- The location to spawn the start mission ped
Config.pedModel = "cs_casey" -- The model of the start mission ped
Config.startItem = "trojan_usb" -- The item used to start the heist
Config.startItemAmount = 2 -- The amount of the item used
Config.consumeItem = true -- Whether the item should be consumed when starting the heist

Config.heistCooldown = 1200000 -- The cooldown time for the heist in milliseconds (1200000 = 20 minutes)
Config.heistTimeout = 900000 -- The time until the heist clears in milliseconds (900000 = 15 minutes)
Config.heistPersist = true -- Whether the heist should persist in the world after completion, set to false to have the heist removed after normal timeout
Config.heistPersistTime = 300000 -- The time until the heist is removed from the world after completion if enabled in milliseconds (600000 = 10 minutes)


Config.C4Item = 'thermite' -- The item required to plant C4 on the truck, should match an item in your inventory system
Config.C4PlantDuration = 3500 -- The time it takes to plant the C4 in milliseconds (3500 matches the animation length)
Config.C4DetonateDuration = 45000 -- The time after planting the C4 until it detonates in milliseconds

Config.universalBlips = false -- Whether to allow all players to see the blip
Config.truckModel = 'stockade' -- The model of the truck used in the robbery
Config.truckLocations = { -- The possible spawn locations for the truck
    vector4(-2008.4460, -485.6441, 10.9029, 44.0234),
    vector4(1446.1288, -2608.3342, 47.7, 344.2553),
    vector4(201.0317, 2792.5288, 45.2, 235.2730)
}

Config.guardModel = 's_m_m_security_01' -- The model of the guards protecting the truck
Config.guardWeapon = 'WEAPON_CARBINERIFLE' -- The weapon used by the guards
Config.guardHostile = false -- Whether the guards will be immediately hostile towards players
Config.guards = 2 -- The number of guards that will spawn with the truck
Config.guardPositions = { -- The possible spawn positions for the guards relative to the truck
    vector3(4.0, 4.0, 0.5),
    vector3(-4.0, 4.0, 0.5),
    vector3(4.0, -4.0, 0.5),
    vector3(-4.0, -4.0, 0.5)
}


Config.grabTime = 2000 -- The time it takes to grab money from the truck in milliseconds
Config.rewards = {
    { item = 'black_money', range = { min = 50000, max = 75000 }, chance = 100 }, -- 100% chance to get between $50,000 and $75,000 in black money
    { item = 'ammo-rifle2', range = { min = 5, max = 15 }, chance = 50 }
}






function Config.policeDispatchExport() -- Export to use when thermite is planted
    local data = exports['cd_dispatch']:GetPlayerInfo()
    TriggerServerEvent('cd_dispatch:AddNotification', {
        job_table = {'lspd', 'swat', 'detectives', 'highway', 'bcso'},
        coords = data.coords,
        title = '10-15 - Bank Truck Robbery',
        message = 'A '..data.sex..' robbing a bank truck at '..data.street, 
        flash = 0,
        unique_id = data.unique_id,
        sound = 1,
        blip = {
            sprite = 431, 
            scale = 1.2, 
            colour = 3,
            flashes = false, 
            text = 'Bank Truck Robbery',
            time = 5,
            radius = 0,
        },
    })
end

Config.initialNotif = false -- Notification when the robbery is started

function Config.initialPoliceDispatchExport() -- Must be server side 
    TriggerEvent('cd_dispatch:AddNotification', {
        job_table = {'lspd', 'swat', 'detectives', 'highway', 'bcso'},
        coords = vec3(0.0, 0.0, 0.0),
        title = 'Bank Truck',
        message = 'A bank truck has broken down somewhere, be on high alert',
        flash = 0,
        unique_id = math.random(99999999),
        sound = 1,
    })
end