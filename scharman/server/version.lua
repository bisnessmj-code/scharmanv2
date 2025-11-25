-- ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
-- ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
-- ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
-- ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
-- ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
-- SERVER VERSION - Vérificateur de version
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════════

local RESOURCE_NAME = 'scharman_ped'
local CURRENT_VERSION = Config.Version

-- URL de vérification (à personnaliser si vous avez un système de versions)
-- local VERSION_CHECK_URL = 'https://votre-site.com/versions/scharman_ped.json'

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Comparer les versions
-- ═══════════════════════════════════════════════════════════════

local function CompareVersions(v1, v2)
    -- Séparer les versions en parties (ex: 1.0.0 -> {1, 0, 0})
    local parts1 = {}
    local parts2 = {}
    
    for part in string.gmatch(v1, '[^%.]+') do
        table.insert(parts1, tonumber(part) or 0)
    end
    
    for part in string.gmatch(v2, '[^%.]+') do
        table.insert(parts2, tonumber(part) or 0)
    end
    
    -- Comparer chaque partie
    for i = 1, math.max(#parts1, #parts2) do
        local p1 = parts1[i] or 0
        local p2 = parts2[i] or 0
        
        if p1 > p2 then
            return 1  -- v1 est plus récente
        elseif p1 < p2 then
            return -1 -- v2 est plus récente
        end
    end
    
    return 0 -- Versions identiques
end

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Vérifier la version
-- ═══════════════════════════════════════════════════════════════

local function CheckVersion()
    Config.InfoPrint('Vérification de la version...')
    
    -- Afficher la version actuelle
    print('═══════════════════════════════════════════════════════════════')
    print('^3' .. RESOURCE_NAME .. '^7 - Version actuelle: ^2' .. CURRENT_VERSION .. '^7')
    print('═══════════════════════════════════════════════════════════════')
    
    -- Note: Vous pouvez ajouter ici une vérification HTTP pour comparer avec une version en ligne
    -- Exemple:
    --[[
    PerformHttpRequest(VERSION_CHECK_URL, function(statusCode, response, headers)
        if statusCode == 200 then
            local data = json.decode(response)
            if data and data.version then
                local comparison = CompareVersions(CURRENT_VERSION, data.version)
                
                if comparison < 0 then
                    print('^3═══════════════════════════════════════════════════════════════^7')
                    print('^1[ATTENTION] Une nouvelle version est disponible!^7')
                    print('^6Version actuelle: ^7' .. CURRENT_VERSION)
                    print('^2Version disponible: ^7' .. data.version)
                    if data.download_url then
                        print('^5Télécharger: ^7' .. data.download_url)
                    end
                    print('^3═══════════════════════════════════════════════════════════════^7')
                elseif comparison == 0 then
                    Config.SuccessPrint('Vous utilisez la dernière version!')
                else
                    Config.InfoPrint('Vous utilisez une version de développement')
                end
            end
        else
            Config.DebugPrint('Impossible de vérifier la version (Code: ' .. statusCode .. ')')
        end
    end, 'GET')
    ]]--
    
    Config.SuccessPrint('Vérification de version terminée')
end

-- ═══════════════════════════════════════════════════════════════
-- DÉMARRAGE
-- ═══════════════════════════════════════════════════════════════

-- Attendre que le serveur soit prêt
CreateThread(function()
    Wait(2000) -- Attendre 2 secondes après le démarrage
    CheckVersion()
end)

Config.DebugPrint('Fichier server/version.lua chargé avec succès')
