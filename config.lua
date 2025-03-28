Config = {}

-- NPC and Vehicle Density Settings
Config.VehicleDensityMultiplier = 0.0 -- Vehicle density (0.0 to 1.0)
Config.PedDensityMultiplier = 0.0 -- NPC density (0.0 to 1.0)

-- Static State Settings
Config.PlayerStaticThreshold = 5.0 -- A player is considered stationary if he moves less than this distance
Config.StaticPositionMultiplier = 0.5 -- When stationary, reduce density by this much

-- Performance Settings
Config.ThreadSleepVehicle = 2500 -- Waiting time for vehicle management
Config.ThreadSleepPed = 3000 -- Waiting time for NPC management
Config.FadeStep = 35 -- Fade out step
Config.FadeWait = 30 -- Fade wait time

-- Cleanup Settings
Config.CleanupTime = 8000 -- 8 seconds (faster cleaning)
Config.CacheCleanupInterval = 25000 -- 25 seconds (more frequent cache cleanup)

-- Spawn Distances and Limits
Config.VehicleSpawnDistance = 30.0 -- Vehicle spawn distance
Config.PedSpawnDistance = 25.0 -- NPC spawn distance
Config.MaxVehiclesInArea = 5 -- Maximum number of vehicles
Config.MaxPedsInArea = 8 -- Maximum number of NPCs

-- Police and Dispatch Settings
Config.DisableCops = true -- Disable the cops
Config.DisableDispatch = true -- Disable dispatch services

-- Cache Settings
Config.MaxCacheSize = 100 -- Maximum cache size

-- Static Check Interval
Config.StaticCheckInterval = 2000 -- 2 seconds

-- New Added Settings
Config.EnableFadeEffect = true -- Enable/disable fade effect
Config.ProtectPlayerVehicles = true -- Protect player vehicles
Config.ProtectPlayerPeds = true -- Protect player NPCs
Config.EnableCache = true -- Enable/disable cache system
Config.EnableStaticCheck = true -- Enable/disable static check
Config.EnableDensityAdjustment = true -- Enable/disable density adjustment

-- Special Settings for Vehicle Classes
Config.ProtectedVehicleClasses = {
    [18] = true, -- Emergency vehicles
    [19] = true, -- Police vehicles
    [15] = true  -- Commercial vehicles
}

-- Special Settings for Ped Types
Config.ProtectedPedTypes = {
    [6] = true, -- Police
    [7] = true, -- Emergency
    [8] = true  -- Special NPCs
}

-- Debug Mode
Config.DebugMode = true -- Enable/disable debug mode
Config.DebugLogLevel = 1 -- Debug log level (1: Only errors, 2: All logs)

return Config 