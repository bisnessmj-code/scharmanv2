-- ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
-- ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
-- ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
-- ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
-- ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
-- SERVER MAIN - Fichier serveur principal
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- VARIABLES GLOBALES
-- ═══════════════════════════════════════════════════════════════

ESX = exports['es_extended']:getSharedObject()

-- Table pour stocker les joueurs ayant l'interface ouverte
local playersWithNuiOpen = {}

-- ═══════════════════════════════════════════════════════════════
-- ÉVÉNEMENT: Démarrage du script
-- ═══════════════════════════════════════════════════════════════

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    Config.SuccessPrint('Script ' .. Config.ScriptName .. ' démarré avec succès!')
    Config.InfoPrint('Version: ' .. Config.Version)
    Config.InfoPrint('Auteur: ESX Legacy')
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    
    -- Vérifier les dépendances
    CheckDependencies()
end)

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Vérifier les dépendances
-- ═══════════════════════════════════════════════════════════════

function CheckDependencies()
    Config.DebugPrint('Vérification des dépendances...')
    
    -- Vérifier ESX
    if not ESX then
        Config.ErrorPrint('ESX n\'est pas chargé! Le script ne fonctionnera pas correctement.')
        return false
    end
    Config.SuccessPrint('ESX détecté et chargé')
    
    -- Vérifier oxmysql
    local mysqlResource = GetResourceState('oxmysql')
    if mysqlResource ~= 'started' then
        Config.ErrorPrint('oxmysql n\'est pas démarré! Le script pourrait ne pas fonctionner correctement.')
    else
        Config.SuccessPrint('oxmysql détecté et démarré')
    end
    
    Config.SuccessPrint('Toutes les dépendances sont OK')
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- ÉVÉNEMENT: Interface ouverte par un joueur
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('scharman:server:nuiOpened', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        Config.ErrorPrint('Joueur introuvable: ' .. source)
        return
    end
    
    -- Ajouter le joueur à la liste
    playersWithNuiOpen[source] = {
        identifier = xPlayer.identifier,
        name = xPlayer.getName(),
        timestamp = os.time()
    }
    
    Config.DebugPrint(('Joueur %s [%s] a ouvert l\'interface'):format(xPlayer.getName(), source))
    
    -- Vous pouvez ajouter ici des vérifications serveur, logging, etc.
end)

-- ═══════════════════════════════════════════════════════════════
-- ÉVÉNEMENT: Interface fermée par un joueur
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('scharman:server:nuiClosed', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        Config.ErrorPrint('Joueur introuvable: ' .. source)
        return
    end
    
    -- Vérifier si le joueur était dans la liste
    if playersWithNuiOpen[source] then
        local openDuration = os.time() - playersWithNuiOpen[source].timestamp
        Config.DebugPrint(('Joueur %s [%s] a fermé l\'interface (durée: %ds)'):format(
            xPlayer.getName(), 
            source, 
            openDuration
        ))
        
        -- Retirer le joueur de la liste
        playersWithNuiOpen[source] = nil
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ÉVÉNEMENT: Joueur déconnecté
-- ═══════════════════════════════════════════════════════════════

AddEventHandler('playerDropped', function(reason)
    local source = source
    
    -- Nettoyer les données du joueur
    if playersWithNuiOpen[source] then
        Config.DebugPrint(('Joueur [%s] déconnecté avec l\'interface ouverte. Nettoyage...'):format(source))
        playersWithNuiOpen[source] = nil
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ÉVÉNEMENT: Arrêt du script
-- ═══════════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    Config.InfoPrint('Arrêt du script ' .. Config.ScriptName)
    
    -- Fermer toutes les interfaces ouvertes
    local count = 0
    for playerId, _ in pairs(playersWithNuiOpen) do
        TriggerClientEvent('scharman:client:nui:close', playerId)
        count = count + 1
    end
    
    if count > 0 then
        Config.InfoPrint(('Fermeture de %d interface(s) ouverte(s)'):format(count))
    end
    
    -- Nettoyer la table
    playersWithNuiOpen = {}
    
    Config.InfoPrint('Script arrêté avec succès')
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
end)

-- ═══════════════════════════════════════════════════════════════
-- COMMANDES ADMIN
-- ═══════════════════════════════════════════════════════════════

if Config.Debug then
    -- Commande pour voir les joueurs avec l'interface ouverte
    RegisterCommand('scharman_list', function(source, args, rawCommand)
        local xPlayer = ESX.GetPlayerFromId(source)
        
        if not xPlayer or not xPlayer.getGroup() == 'admin' then
            return
        end
        
        print('═══════════════════════════════════════════════════════════════')
        print('Joueurs avec l\'interface ouverte:')
        print('═══════════════════════════════════════════════════════════════')
        
        local count = 0
        for playerId, data in pairs(playersWithNuiOpen) do
            count = count + 1
            local duration = os.time() - data.timestamp
            print(('%d. %s [ID: %s] - Ouvert depuis: %ds'):format(count, data.name, playerId, duration))
        end
        
        if count == 0 then
            print('Aucun joueur n\'a l\'interface ouverte')
        end
        
        print('═══════════════════════════════════════════════════════════════')
    end, true)
    
    Config.InfoPrint('Commande admin disponible: /scharman_list (affiche les joueurs avec l\'interface ouverte)')
end

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS SERVEUR
-- ═══════════════════════════════════════════════════════════════

-- Export pour obtenir la liste des joueurs avec l'interface ouverte
exports('GetPlayersWithNuiOpen', function()
    return playersWithNuiOpen
end)

-- Export pour forcer la fermeture de l'interface d'un joueur
exports('ForceCloseNUI', function(playerId)
    if playersWithNuiOpen[playerId] then
        TriggerClientEvent('scharman:client:nui:close', playerId)
        playersWithNuiOpen[playerId] = nil
        return true
    end
    return false
end)

-- Export pour vérifier si un joueur a l'interface ouverte
exports('IsPlayerNuiOpen', function(playerId)
    return playersWithNuiOpen[playerId] ~= nil
end)

Config.DebugPrint('Fichier server/main.lua chargé avec succès')
