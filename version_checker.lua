local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
local resourceName = GetCurrentResourceName()

print('^2[' .. resourceName .. '] Version checker başlatılıyor...^7')
print('^2[' .. resourceName .. '] Mevcut versiyon: ' .. currentVersion .. '^7')

local function checkVersion()
    print('^2[' .. resourceName .. '] GitHub\'dan versiyon kontrol ediliyor...^7')
    
    PerformHttpRequest('https://raw.githubusercontent.com/JArtew/artew-npc-control/main/fxmanifest.lua', function(err, text, headers)
        print('^2[' .. resourceName .. '] HTTP Response Code: ' .. tostring(err) .. '^7')
        
        if err ~= 200 then
            print('^1[' .. resourceName .. '] Version kontrol edilemedi! Hata kodu: ' .. tostring(err) .. '^7')
            return
        end
        
        if text then
            print('^2[' .. resourceName .. '] GitHub\'dan veri alındı. İçerik uzunluğu: ' .. string.len(text) .. '^7')
        else
            print('^1[' .. resourceName .. '] GitHub\'dan veri alınamadı!^7')
            return
        end
        
        local latestVersion = string.match(text, "version%s*'([^']+)'")
        
        if latestVersion then
            print('^2[' .. resourceName .. '] GitHub\'daki versiyon: ' .. latestVersion .. '^7')
            
            if currentVersion ~= latestVersion then
                print('^3╔════════════════════════════════════════════╗^7')
                print('^3║            GÜNCELLEME MEVCUT!              ║^7')
                print('^3║ Mevcut versiyon: ' .. string.format('%-24s', currentVersion) .. ' ║^7')
                print('^3║ Yeni versiyon: ' .. string.format('%-26s', latestVersion) .. ' ║^7')
                print('^3║ Güncelleme için:                           ║^7')
                print('^3║ github.com/JArtew/artew-npc-control        ║^7')
                print('^3╚════════════════════════════════════════════╝^7')
            else
                print('^2[' .. resourceName .. '] Script güncel! (v' .. currentVersion .. ')^7')
            end
        else
            print('^1[' .. resourceName .. '] GitHub dosyasında version bilgisi bulunamadı!^7')
            print('^1[' .. resourceName .. '] Alınan içerik: ' .. text .. '^7')
        end
    end)
end

CreateThread(function()
    Wait(5000) -- Sunucu başladıktan 5 saniye sonra kontrol et
    checkVersion()
end) 