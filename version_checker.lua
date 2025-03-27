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
        end
    end)
end

CreateThread(function()
    Wait(5000) -- Sunucu başladıktan 5 saniye sonra kontrol et
    checkVersion()
end) 