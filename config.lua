Config = {}

Config.truckModel = 'stockade' -- The model of the truck used in the robbery
Config.truckLocations = { -- The possible spawn locations for the truck
    vector4(-356.4294, -91.6064, 45.6567, 252.2835),
}

Config.C4Item = 'ammo-9' -- The item required to plant C4 on the truck, should match an item in your inventory system
Config.C4PlantDuration = 3500 -- The time it takes to plant the C4 in milliseconds (3500 matches the animation length)
Config.C4DetonateDuration = 10000 -- The time after planting the C4 until it detonates in milliseconds

Config.guardModel = 's_m_m_security_01' -- The model of the guards protecting the truck
Config.guardWeapon = 'WEAPON_CARBINERIFLE' -- The weapon used by the guards
Config.guardHostile = false -- Whether the guards will be immediately hostile towards players
Config.guards = 4 -- The number of guards that will spawn with the truck
Config.guardPositions = { -- The possible spawn positions for the guards relative to the truck
    vector3(4.0, 4.0, 0.0),
    vector3(-4.0, 4.0, 0.0),
    vector3(4.0, -4.0, 0.0),
    vector3(-4.0, -4.0, 0.0)
}

Config.grabTime = 2000 -- The time it takes to grab money from the truck in milliseconds
Config.rewards = {
    { item = 'black_money', range = { min = 10000, max = 15000 }, chance = 100 }, -- 100% chance to get between $10,000 and $15,000 in black money
    { item = 'ammo-rifle2', range = { min = 5, max = 15 }, chance = 50 }
}