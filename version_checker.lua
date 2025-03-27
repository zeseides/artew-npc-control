local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
local resourceName = GetCurrentResourceName()

local function checkVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/JArtew/artew-npc-control/main/fxmanifest.lua', function(err, text, headers)
        if err ~= 200 then
            print('^1[' .. resourceName .. '] Version kontrol edilemedi!^7')
            return
        end
        
        local latestVersion = string.match(text, "version%s*'([^']+)'")
        
        if latestVersion then
            if currentVersion ~= latestVersion then
                print('^3[' .. resourceName .. '] Yeni bir güncelleme mevcut!^7')
                print('^3[' .. resourceName .. '] Mevcut versiyon: ' .. currentVersion .. '^7')
                print('^3[' .. resourceName .. '] Yeni versiyon: ' .. latestVersion .. '^7')
                print('^3[' .. resourceName .. '] Güncelleme için: https://github.com/JArtew/artew-npc-control/releases^7')
            else
                print('^2[' .. resourceName .. '] Script güncel! (v' .. currentVersion .. ')^7')
            end
        else
            print('^1[' .. resourceName .. '] Version bilgisi alınamadı!^7')
        end
    end)
end

CreateThread(function()
    Wait(5000) -- Sunucu başladıktan 5 saniye sonra kontrol et
    checkVersion()
end) 