-- ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
-- ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
-- ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
-- ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
-- ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
-- CLIENT MAIN - Initialisation et gestion principale
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- VARIABLES GLOBALES
-- ═══════════════════════════════════════════════════════════════

-- État de l'interface (ouverte/fermée)
local isNuiOpen = false

-- État ESX
ESX = exports['es_extended']:getSharedObject()

-- ═══════════════════════════════════════════════════════════════
-- ÉVÉNEMENT: Démarrage du script
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    Config.InfoPrint('Initialisation du script client...')
    
    -- Attendre que le joueur soit complètement chargé
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end
    
    Config.SuccessPrint('Script client initialisé avec succès!')
    Config.DebugPrint('Version: ' .. Config.Version)
    
    -- Déclencher l'initialisation des modules
    TriggerEvent('scharman:client:initialize')
end)

-- ═══════════════════════════════════════════════════════════════
-- ÉVÉNEMENT: Initialisation des modules
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('scharman:client:initialize', function()
    Config.DebugPrint('Initialisation des modules...')
    
    -- Initialiser le PED
    if Config.Ped.enabled then
        TriggerEvent('scharman:client:ped:spawn')
        Config.DebugPrint('Module PED initialisé')
    end
    
    -- Initialiser le blip
    if Config.Blip.enabled then
        TriggerEvent('scharman:client:blip:create')
        Config.DebugPrint('Module BLIP initialisé')
    end
    
    -- Initialiser le système d'interaction
    TriggerEvent('scharman:client:interaction:start')
    Config.DebugPrint('Module INTERACTION initialisé')
end)

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Récupérer l'état de l'interface
-- ═══════════════════════════════════════════════════════════════

function GetNuiState()
    return isNuiOpen
end

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Définir l'état de l'interface
-- ═══════════════════════════════════════════════════════════════

function SetNuiState(state)
    isNuiOpen = state
    Config.DebugPrint('État NUI changé: ' .. tostring(state))
end

-- ═══════════════════════════════════════════════════════════════
-- COMMANDE DE DEBUG: Afficher les informations du script
-- ═══════════════════════════════════════════════════════════════

if Config.Debug then
    RegisterCommand('scharman_info', function()
        print('═══════════════════════════════════════════════════════════════')
        print('^3' .. Config.ScriptName .. '^7 - Informations')
        print('═══════════════════════════════════════════════════════════════')
        print('^6Version:^7 ' .. Config.Version)
        print('^6État NUI:^7 ' .. tostring(isNuiOpen))
        print('^6PED Activé:^7 ' .. tostring(Config.Ped.enabled))
        print('^6Blip Activé:^7 ' .. tostring(Config.Blip.enabled))
        print('^6Position PED:^7 ' .. tostring(Config.Ped.coords))
        print('═══════════════════════════════════════════════════════════════')
    end, false)
    
    Config.InfoPrint('Commande de debug disponible: /scharman_info')
end

-- ═══════════════════════════════════════════════════════════════
-- COMMANDE DE DEBUG: Réinitialiser le script
-- ═══════════════════════════════════════════════════════════════

if Config.Debug then
    RegisterCommand('scharman_reload', function()
        Config.InfoPrint('Réinitialisation du script...')
        
        -- Fermer l'interface si ouverte
        if isNuiOpen then
            TriggerEvent('scharman:client:nui:close')
        end
        
        -- Supprimer le PED
        TriggerEvent('scharman:client:ped:delete')
        
        -- Attendre un peu
        Wait(500)
        
        -- Réinitialiser
        TriggerEvent('scharman:client:initialize')
        
        Config.SuccessPrint('Script réinitialisé!')
    end, false)
    
    Config.InfoPrint('Commande de debug disponible: /scharman_reload')
end

-- ═══════════════════════════════════════════════════════════════
-- ÉVÉNEMENT: Nettoyage lors de la déconnexion
-- ═══════════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Config.InfoPrint('Arrêt du script, nettoyage en cours...')
    
    -- Fermer l'interface
    if isNuiOpen then
        TriggerEvent('scharman:client:nui:close')
    end
    
    -- Supprimer le PED
    TriggerEvent('scharman:client:ped:delete')
    
    Config.SuccessPrint('Nettoyage terminé')
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS (Pour d'autres scripts)
-- ═══════════════════════════════════════════════════════════════

-- Export pour ouvrir l'interface depuis un autre script
exports('OpenNUI', function()
    if not isNuiOpen then
        TriggerEvent('scharman:client:nui:open')
        return true
    end
    return false
end)

-- Export pour fermer l'interface depuis un autre script
exports('CloseNUI', function()
    if isNuiOpen then
        TriggerEvent('scharman:client:nui:close')
        return true
    end
    return false
end)

-- Export pour obtenir l'état de l'interface
exports('IsNUIOpen', function()
    return isNuiOpen
end)

-- Export pour obtenir les coordonnées du PED
exports('GetPedCoords', function()
    return Config.Ped.coords
end)

Config.DebugPrint('Fichier client/main.lua chargé avec succès')
