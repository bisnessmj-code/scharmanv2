-- SERVER - VERSION
local SCRIPT_NAME = 'Scharman PED'
local SCRIPT_VERSION = '2.0.0'
local SCRIPT_AUTHOR = 'ESX Legacy (Modifié)'

local function CheckDependencies()
    if GetResourceState('es_extended') ~= 'started' then
        Config.ErrorPrint('ESX Legacy n\'est pas démarré')
        return false
    end
    Config.SuccessPrint('ESX détecté')
    
    if GetResourceState('oxmysql') ~= 'started' then
        Config.ErrorPrint('oxmysql n\'est pas démarré')
        return false
    end
    Config.SuccessPrint('oxmysql détecté')
    return true
end

CreateThread(function()
    print('^6═══════════════════════════════════════════════════════════════^7')
    print('^2Script ' .. SCRIPT_NAME .. ' démarré avec succès!^7')
    print('^6Version:^7 ' .. SCRIPT_VERSION)
    print('^6Auteur:^7 ' .. SCRIPT_AUTHOR)
    print('^6═══════════════════════════════════════════════════════════════^7')
    
    if not CheckDependencies() then
        Config.ErrorPrint('Échec de la vérification des dépendances')
        return
    end
    Config.SuccessPrint('Toutes les dépendances sont OK')
end)

Config.DebugPrint('server/version.lua chargé')
