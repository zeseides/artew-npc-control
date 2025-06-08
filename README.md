# 🏃 Artew NPC 控制系統

這個腳本是為 FiveM 優化的**載具和行人管理**系統。透過其**FPS 友善**的架構，清除伺服器中不必要的載具和行人，提供更流暢的遊戲體驗。

## 📌 功能特色

- **基於 FPS 的優化** – 根據 FPS 數值自動調整載具和行人密度。
- **隱形載具/行人清理** – 移除長時間未在螢幕上顯示的實體。
- **載具和行人限制** – 防止創建超過指定限制的載具/行人。
- **緩慢刪除效果** – 載具和行人不會突然消失，而是緩慢淡出。
- **警察和緊急服務停用** – 可選擇性地阻止警察和救護車生成。
- **FPS 基礎密度優化** - 如果 FPS 下降，會根據 FPS 值自動增加或減少密度。
- **更智能的生成距離** → NPC 和載具在適合玩家視角的距離生成，防止不必要的處理負載。
- **交通生成控制** → 您可以控制想要的載具生成。
- **玩家靜止狀態功能** → 玩家移動少於 5 單位時被視為靜止，靜止狀態時密度降低 50%，每 2 秒檢查一次靜止狀態，靜止時更積極的清理。
- **智能生成系統** → 靜止時 30% 生成機率，移動時 70% 生成機率，基於距離的生成控制，基於 FPS 的生成優化。

## 🔧 安裝說明

1. 下載檔案並放置在名為 `artew-npc-control` 的資料夾中。
2. 開啟您的 `server.cfg` 檔案並新增以下行：
   ```cfg
   ensure artew-npc-control
   ```
3. 重新啟動您的伺服器。

## ⚙️ 配置設定

您可以透過編輯 `config.lua` 檔案來根據需求自訂腳本。

### 重要變數  
- `VehicleDensityMultiplier`：決定載具密度。（0.0 - 1.0 之間）  
- `PedDensityMultiplier`：決定行人密度。（0.0 - 1.0 之間）
- `PlayerStaticThreshold`：玩家移動少於此距離時被視為靜止
- `StaticPositionMultiplier`：靜止位置時降低的密度倍數
- `DisableCops` 和 `DisableDispatch`：允許停用警察和緊急單位。
- `vehicleSpawnDistance` 和 `pedSpawnDistance`：載具和行人生成距離   
- `maxVehiclesInArea`：限制最大載具數量。  
- `maxPedsInArea`：限制最大行人數量。  
- `cleanupTime`：清除隱形實體的時間（以毫秒為單位）。
- `EnableFadeEffect`：啟用/停用淡出效果
- `ProtectPlayerVehicles`：保護玩家載具
- `ProtectPlayerPeds`：保護玩家 NPC
- `EnableStaticCheck`：啟用/停用靜止檢查
- `EnableDensityAdjustment`：啟用/停用密度調整
- `DebugMode`：啟用/停用除錯模式
- `DebugLogLevel`：除錯日誌等級（1：僅錯誤，2：所有日誌）

## 🔧 Resmon 數值
![Resmon](https://github.com/user-attachments/assets/7d49fe0d-7dbc-4501-9454-bb88d0a757da)

Resmon 數值最高將在 0.0-0.2 之間。
