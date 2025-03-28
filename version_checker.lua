local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
local resourceName = GetCurrentResourceName()

local function checkVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/JArtew/artew-npc-control/main/fxmanifest.lua', function(err, text, headers)
        if err ~= 200 then
            print('^1[' .. resourceName .. '] Version could not be checked!^7')
            return
        end
        
        
        local latestVersion = string.match(text, "version%s*'([0-9]+%.[0-9]+%.[0-9]+)'")
        
        if latestVersion then
            
            currentVersion = string.gsub(currentVersion, "^%s*(.-)%s*$", "%1")
            latestVersion = string.gsub(latestVersion, "^%s*(.-)%s*$", "%1")
            
            if currentVersion ~= latestVersion then
                print('^3╔════════════════════════════════════════════╗^7')
                print('^3║            UPDATE AVAILABLE!               ║^7')
                print('^3║ Current version: ' .. string.format('%-24s', currentVersion) .. ' ║^7')
                print('^3║ New version: ' .. string.format('%-26s', latestVersion) .. ' ║^7')
                print('^3║ For updates:                               ║^7')
                print('^3║ github.com/JArtew/artew-npc-control        ║^7')
                print('^3╚════════════════════════════════════════════╝^7')
            else
                print('^2[' .. resourceName .. '] The script is current! (v' .. currentVersion .. ')^7')
            end
        end
    end)
end

CreateThread(function()
    Wait(5000) 
    checkVersion()
end) 