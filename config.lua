Config = {}
-- NPC 和載具密度設定
Config.VehicleDensityMultiplier = 0.0 -- 載具密度 (0.0 到 1.0)
Config.PedDensityMultiplier = 0.0 -- NPC 密度 (0.0 到 1.0)
-- 靜止狀態設定
Config.PlayerStaticThreshold = 5.0 -- 玩家移動距離小於此值時視為靜止
Config.StaticPositionMultiplier = 0.5 -- 靜止時，密度降低的倍數
-- 效能設定
Config.ThreadSleepVehicle = 2500 -- 載具管理的等待時間
Config.ThreadSleepPed = 3000 -- NPC 管理的等待時間
Config.FadeStep = 35 -- 淡出步驟
Config.FadeWait = 30 -- 淡出等待時間
-- 清理設定
Config.CleanupTime = 8000 -- 8 秒（更快的清理）
Config.CacheCleanupInterval = 25000 -- 25 秒（更頻繁的快取清理）
-- 生成距離和限制
Config.VehicleSpawnDistance = 30.0 -- 載具生成距離
Config.PedSpawnDistance = 25.0 -- NPC 生成距離
Config.MaxVehiclesInArea = 5 -- 區域內最大載具數量
Config.MaxPedsInArea = 8 -- 區域內最大 NPC 數量
-- 警察和派遣設定
Config.DisableCops = true -- 停用警察
Config.DisableDispatch = true -- 停用派遣服務
-- 快取設定
Config.MaxCacheSize = 100 -- 最大快取大小
-- 靜止檢查間隔
Config.StaticCheckInterval = 2000 -- 2 秒
-- 新增設定
Config.EnableFadeEffect = true -- 啟用/停用淡出效果
Config.ProtectPlayerVehicles = true -- 保護玩家載具
Config.ProtectPlayerPeds = true -- 保護玩家 NPC
Config.EnableCache = true -- 啟用/停用快取系統
Config.EnableStaticCheck = true -- 啟用/停用靜止檢查
Config.EnableDensityAdjustment = true -- 啟用/停用密度調整
-- 載具類別的特殊設定
Config.ProtectedVehicleClasses = {
    [18] = true, -- 緊急載具
    [19] = true, -- 警用載具
    [15] = true  -- 商用載具
}
-- NPC 類型的特殊設定
Config.ProtectedPedTypes = {
    [6] = true, -- 警察
    [7] = true, -- 緊急人員
    [8] = true  -- 特殊 NPC
}
-- 除錯模式
Config.DebugMode = true -- 啟用/停用除錯模式
Config.DebugLogLevel = 1 -- 除錯日誌等級 (1: 僅錯誤, 2: 所有日誌)
return Config
