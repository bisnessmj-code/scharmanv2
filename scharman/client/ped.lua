-- ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
-- ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
-- ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
-- ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
-- ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
-- CLIENT PED - Gestion du PED Scharman
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- VARIABLES LOCALES
-- ═══════════════════════════════════════════════════════════════

-- Référence du PED spawné
local scharmanPed = nil

-- Référence du blip
local scharmanBlip = nil

-- Statut du PED (spawné ou non)
local isPedSpawned = false

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Charger le modèle du PED
-- ═══════════════════════════════════════════════════════════════

local function LoadPedModel(model)
    Config.DebugPrint('Chargement du modèle: ' .. model)
    
    -- Demander le chargement du modèle
    RequestModel(GetHashKey(model))
    
    -- Attendre que le modèle soit chargé (timeout de 10 secondes)
    local timeout = 0
    while not HasModelLoaded(GetHashKey(model)) do
        Wait(100)
        timeout = timeout + 100
        
        if timeout >= 10000 then
            Config.ErrorPrint('Timeout lors du chargement du modèle: ' .. model)
            return false
        end
    end
    
    Config.DebugPrint('Modèle chargé avec succès: ' .. model)
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Spawner le PED
-- ═══════════════════════════════════════════════════════════════

local function SpawnPed()
    Config.DebugPrint('Tentative de spawn du PED...')
    
    -- Vérifier si le PED existe déjà
    if DoesEntityExist(scharmanPed) then
        Config.DebugPrint('Le PED existe déjà, suppression...')
        DeleteEntity(scharmanPed)
        scharmanPed = nil
    end
    
    -- Charger le modèle
    if not LoadPedModel(Config.Ped.model) then
        Config.ErrorPrint('Impossible de charger le modèle du PED')
        return false
    end
    
    -- Créer le PED
    local coords = Config.Ped.coords
    scharmanPed = CreatePed(4, GetHashKey(Config.Ped.model), coords.x, coords.y, coords.z, coords.w, false, true)
    
    -- Vérifier que le PED a été créé
    if not DoesEntityExist(scharmanPed) then
        Config.ErrorPrint('Échec de la création du PED')
        SetModelAsNoLongerNeeded(GetHashKey(Config.Ped.model))
        return false
    end
    
    Config.DebugPrint('PED créé avec succès (ID: ' .. scharmanPed .. ')')
    
    -- Configuration du PED
    -- Rendre le PED invincible si configuré
    if Config.Ped.invincible then
        SetEntityInvincible(scharmanPed, true)
        Config.DebugPrint('PED configuré comme invincible')
    end
    
    -- Figer le PED si configuré
    if Config.Ped.frozen then
        FreezeEntityPosition(scharmanPed, true)
        Config.DebugPrint('PED figé en position')
    end
    
    -- Bloquer les événements si configuré
    if Config.Ped.blockEvents then
        SetBlockingOfNonTemporaryEvents(scharmanPed, true)
        Config.DebugPrint('Événements du PED bloqués')
    end
    
    -- Appliquer un scenario ou une animation
    if Config.Ped.scenario then
        TaskStartScenarioInPlace(scharmanPed, Config.Ped.scenario, 0, true)
        Config.DebugPrint('Scenario appliqué: ' .. Config.Ped.scenario)
    elseif Config.Ped.animation then
        -- Charger le dictionnaire d'animation
        RequestAnimDict(Config.Ped.animation.dict)
        while not HasAnimDictLoaded(Config.Ped.animation.dict) do
            Wait(100)
        end
        TaskPlayAnim(scharmanPed, Config.Ped.animation.dict, Config.Ped.animation.anim, 8.0, 0.0, -1, Config.Ped.animation.flag, 0, false, false, false)
        Config.DebugPrint('Animation appliquée: ' .. Config.Ped.animation.dict .. ' / ' .. Config.Ped.animation.anim)
    end
    
    -- Libérer le modèle (optimisation mémoire)
    SetModelAsNoLongerNeeded(GetHashKey(Config.Ped.model))
    
    isPedSpawned = true
    Config.SuccessPrint(Config.Texts.pedSpawned)
    
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Supprimer le PED
-- ═══════════════════════════════════════════════════════════════

local function DeletePed()
    Config.DebugPrint('Suppression du PED...')
    
    if DoesEntityExist(scharmanPed) then
        DeleteEntity(scharmanPed)
        scharmanPed = nil
        isPedSpawned = false
        Config.SuccessPrint(Config.Texts.pedDeleted)
    else
        Config.DebugPrint('Aucun PED à supprimer')
    end
end

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Créer le blip
-- ═══════════════════════════════════════════════════════════════

local function CreateBlip()
    Config.DebugPrint('Création du blip...')
    
    -- Supprimer l'ancien blip s'il existe
    if DoesBlipExist(scharmanBlip) then
        RemoveBlip(scharmanBlip)
        Config.DebugPrint('Ancien blip supprimé')
    end
    
    -- Créer le nouveau blip
    local coords = Config.Ped.coords
    scharmanBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    
    -- Configuration du blip
    SetBlipSprite(scharmanBlip, Config.Blip.sprite)
    SetBlipDisplay(scharmanBlip, 4)
    SetBlipScale(scharmanBlip, Config.Blip.scale)
    SetBlipColour(scharmanBlip, Config.Blip.color)
    SetBlipAsShortRange(scharmanBlip, Config.Blip.isShortRange)
    
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(Config.Blip.label)
    EndTextCommandSetBlipName(scharmanBlip)
    
    Config.SuccessPrint(Config.Texts.blipCreated)
end

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Supprimer le blip
-- ═══════════════════════════════════════════════════════════════

local function DeleteBlip()
    if DoesBlipExist(scharmanBlip) then
        RemoveBlip(scharmanBlip)
        scharmanBlip = nil
        Config.DebugPrint('Blip supprimé')
    end
end

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Vérifier si le joueur est proche du PED
-- ═══════════════════════════════════════════════════════════════

function IsPlayerNearPed()
    if not isPedSpawned or not DoesEntityExist(scharmanPed) then
        return false
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local pedCoords = GetEntityCoords(scharmanPed)
    local distance = #(playerCoords - pedCoords)
    
    return distance <= Config.Ped.interactionDistance
end

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Récupérer la distance entre le joueur et le PED
-- ═══════════════════════════════════════════════════════════════

function GetDistanceToPed()
    if not isPedSpawned or not DoesEntityExist(scharmanPed) then
        return 9999
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local pedCoords = GetEntityCoords(scharmanPed)
    
    return #(playerCoords - pedCoords)
end

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Récupérer les coordonnées du PED
-- ═══════════════════════════════════════════════════════════════

function GetPedCoords()
    if isPedSpawned and DoesEntityExist(scharmanPed) then
        return GetEntityCoords(scharmanPed)
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════
-- BOUCLE: Gestion du rendu et de l'affichage du marqueur
-- ═══════════════════════════════════════════════════════════════

if Config.Marker.enabled then
    CreateThread(function()
        while true do
            local sleep = 1000
            
            if isPedSpawned and DoesEntityExist(scharmanPed) then
                local playerCoords = GetEntityCoords(PlayerPedId())
                local pedCoords = GetEntityCoords(scharmanPed)
                local distance = #(playerCoords - pedCoords)
                
                -- Si le joueur est dans la distance d'affichage
                if distance <= Config.Marker.drawDistance then
                    sleep = 0
                    
                    -- Dessiner le marqueur
                    DrawMarker(
                        Config.Marker.type,
                        pedCoords.x, pedCoords.y, pedCoords.z - 0.98,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        Config.Marker.size.x, Config.Marker.size.y, Config.Marker.size.z,
                        Config.Marker.color.r, Config.Marker.color.g, Config.Marker.color.b, Config.Marker.color.a,
                        false, true, 2, Config.Marker.rotate, nil, nil, false
                    )
                    
                    -- Si le joueur est dans la distance d'interaction
                    if distance <= Config.Ped.interactionDistance then
                        -- Afficher le texte d'aide
                        ESX.ShowHelpNotification(Config.Marker.helpText)
                        
                        -- Détecter l'appui sur E (ou INPUT_CONTEXT)
                        if IsControlJustReleased(0, 38) then -- Touche E
                            Config.DebugPrint('Interaction avec le PED détectée')
                            TriggerEvent('scharman:client:nui:open')
                        end
                    end
                end
            end
            
            Wait(sleep)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- ÉVÉNEMENTS
-- ═══════════════════════════════════════════════════════════════

-- Événement pour spawner le PED
RegisterNetEvent('scharman:client:ped:spawn', function()
    SpawnPed()
end)

-- Événement pour supprimer le PED
RegisterNetEvent('scharman:client:ped:delete', function()
    DeletePed()
    DeleteBlip()
end)

-- Événement pour créer le blip
RegisterNetEvent('scharman:client:blip:create', function()
    CreateBlip()
end)

-- Événement pour supprimer le blip
RegisterNetEvent('scharman:client:blip:delete', function()
    DeleteBlip()
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('GetPedEntity', function()
    return scharmanPed
end)

exports('IsPedSpawned', function()
    return isPedSpawned
end)

exports('GetDistanceToPed', function()
    return GetDistanceToPed()
end)

Config.DebugPrint('Fichier client/ped.lua chargé avec succès')
