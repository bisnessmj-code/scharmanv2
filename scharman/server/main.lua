-- ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
-- ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
-- ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
-- ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
-- ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
-- SERVER - MAIN
-- ═══════════════════════════════════════════════════════════════

ESX = exports['es_extended']:getSharedObject()

-- ═══════════════════════════════════════════════════════════════
-- VARIABLES GLOBALES
-- ═══════════════════════════════════════════════════════════════

local playersWithNuiOpen = {}

-- ═══════════════════════════════════════════════════════════════
-- ÉVÉNEMENTS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('scharman:server:nuiOpened', function()
    local source = source
    playersWithNuiOpen[source] = true
    Config.DebugPrint('Joueur ' .. source .. ' a ouvert l\'interface')
end)

RegisterNetEvent('scharman:server:nuiClosed', function()
    local source = source
    playersWithNuiOpen[source] = nil
    Config.DebugPrint('Joueur ' .. source .. ' a fermé l\'interface')
end)

-- ═══════════════════════════════════════════════════════════════
-- COMMANDES ADMIN
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('scharman_list', function(source, args, rawCommand)
    if source > 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or xPlayer.getGroup() ~= 'admin' then
            return
        end
    end
    
    print('═══════════════════════════════════════════════════════════════')
    print('Joueurs avec l\'interface Scharman ouverte:')
    print('═══════════════════════════════════════════════════════════════')
    
    local count = 0
    for playerId, _ in pairs(playersWithNuiOpen) do
        count = count + 1
        local xPlayer = ESX.GetPlayerFromId(playerId)
        local name = xPlayer and xPlayer.getName() or 'Inconnu'
        print(count .. '. ' .. name .. ' [ID: ' .. playerId .. ']')
    end
    
    if count == 0 then
        print('Aucun joueur')
    end
    
    print('═══════════════════════════════════════════════════════════════')
    print('Total: ' .. count .. ' joueur(s)')
    print('═══════════════════════════════════════════════════════════════')
end, true)

-- ═══════════════════════════════════════════════════════════════
-- INITIALISATION
-- ═══════════════════════════════════════════════════════════════

Config.InfoPrint('Commande admin disponible: /scharman_list (affiche les joueurs avec l\'interface ouverte)')
Config.DebugPrint('Fichier server/main.lua chargé avec succès')
