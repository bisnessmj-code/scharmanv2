-- ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
-- ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
-- ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
-- ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
-- ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
-- CLIENT - PED
-- ═══════════════════════════════════════════════════════════════

local scharmanPed = nil
local scharmanBlip = nil

-- ═══════════════════════════════════════════════════════════════
-- FONCTIONS PED
-- ═══════════════════════════════════════════════════════════════

local function SpawnScharmanPed()
    Config.DebugPrint('Tentative de spawn du PED...')
    
    local modelHash = GetHashKey(Config.Ped.model)
    
    -- Charger le modèle
    Config.DebugPrint('Chargement du modèle: ' .. Config.Ped.model)
    RequestModel(modelHash)
    
    local timeout = 0
    while not HasModelLoaded(modelHash) do
        Wait(100)
        timeout = timeout + 100
        
        if timeout >= 10000 then
            Config.ErrorPrint('Timeout lors du chargement du modèle PED')
            return false
        end
    end
    
    Config.DebugPrint('Modèle chargé avec succès: ' .. Config.Ped.model)
    
    -- Créer le PED
    scharmanPed = CreatePed(
        4,
        modelHash,
        Config.Ped.coords.x,
        Config.Ped.coords.y,
        Config.Ped.coords.z,
        Config.Ped.coords.w,
        false,
        false
    )
    
    if not DoesEntityExist(scharmanPed) then
        Config.ErrorPrint('Échec de la création du PED')
        return false
    end
    
    Config.DebugPrint('PED créé avec succès (ID: ' .. scharmanPed .. ')')
    
    -- Configuration du PED
    if Config.Ped.invincible then
        SetEntityInvincible(scharmanPed, true)
        Config.DebugPrint('PED configuré comme invincible')
    end
    
    if Config.Ped.freeze then
        FreezeEntityPosition(scharmanPed, true)
        Config.DebugPrint('PED figé en position')
    end
    
    if Config.Ped.blockEvents then
        SetBlockingOfNonTemporaryEvents(scharmanPed, true)
        Config.DebugPrint('Événements du PED bloqués')
    end
    
    -- Appliquer le scénario
    if Config.Ped.scenario then
        TaskStartScenarioInPlace(scharmanPed, Config.Ped.scenario, 0, true)
        Config.DebugPrint('Scenario appliqué: ' .. Config.Ped.scenario)
    end
    
    -- Libérer le modèle
    SetModelAsNoLongerNeeded(modelHash)
    
    Config.SuccessPrint(Config.Texts.pedSpawned)
    return true
end

local function DeleteScharmanPed()
    if DoesEntityExist(scharmanPed) then
        DeleteEntity(scharmanPed)
        scharmanPed = nil
        Config.DebugPrint('PED supprimé')
    end
end

-- ═══════════════════════════════════════════════════════════════
-- FONCTIONS BLIP
-- ═══════════════════════════════════════════════════════════════

local function CreateScharmanBlip()
    if not Config.Blip.enabled then
        return
    end
    
    Config.DebugPrint('Création du blip...')
    
    scharmanBlip = AddBlipForCoord(Config.Ped.coords.x, Config.Ped.coords.y, Config.Ped.coords.z)
    
    SetBlipSprite(scharmanBlip, Config.Blip.sprite)
    SetBlipDisplay(scharmanBlip, Config.Blip.display)
    SetBlipScale(scharmanBlip, Config.Blip.scale)
    SetBlipColour(scharmanBlip, Config.Blip.color)
    SetBlipAsShortRange(scharmanBlip, true)
    
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(Config.Blip.name)
    EndTextCommandSetBlipName(scharmanBlip)
    
    Config.SuccessPrint(Config.Texts.blipCreated)
end

local function DeleteScharmanBlip()
    if DoesBlipExist(scharmanBlip) then
        RemoveBlip(scharmanBlip)
        scharmanBlip = nil
        Config.DebugPrint('Blip supprimé')
    end
end

-- ═══════════════════════════════════════════════════════════════
-- SYSTÈME D'INTERACTION
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local pedCoords = vector3(Config.Ped.coords.x, Config.Ped.coords.y, Config.Ped.coords.z)
        local distance = #(playerCoords - pedCoords)
        
        if distance < 10.0 then
            sleep = 0
            
            -- Afficher le marqueur
            if Config.Marker.enabled and distance < 5.0 then
                DrawMarker(
                    Config.Marker.type,
                    Config.Ped.coords.x,
                    Config.Ped.coords.y,
                    Config.Ped.coords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    Config.Marker.size.x,
                    Config.Marker.size.y,
                    Config.Marker.size.z,
                    Config.Marker.color.r,
                    Config.Marker.color.g,
                    Config.Marker.color.b,
                    Config.Marker.color.a,
                    Config.Marker.bobUpAndDown,
                    Config.Marker.faceCamera,
                    2,
                    Config.Marker.rotate,
                    nil,
                    nil,
                    false
                )
            end
            
            -- Afficher le texte d'aide
            if distance < Config.Interaction.distance then
                ESX.ShowHelpNotification(Config.Interaction.label)
                
                -- Détecter l'appui sur la touche
                if IsControlJustReleased(0, Config.Interaction.key) then
                    Config.DebugPrint(Config.Texts.interactionDetected)
                    TriggerEvent('scharman:client:openNUI')
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- INITIALISATION
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    -- Spawn du PED
    if not SpawnScharmanPed() then
        Config.ErrorPrint('Échec du spawn du PED')
        return
    end
    
    Config.DebugPrint('Module PED initialisé')
    
    -- Création du blip
    CreateScharmanBlip()
    Config.DebugPrint('Module BLIP initialisé')
    
    Config.DebugPrint('Système d\'interaction démarré')
    Config.DebugPrint('Module INTERACTION initialisé')
end)

-- ═══════════════════════════════════════════════════════════════
-- ÉVÉNEMENTS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('scharman:client:reload', function()
    DeleteScharmanPed()
    DeleteScharmanBlip()
    Wait(500)
    SpawnScharmanPed()
    CreateScharmanBlip()
    Config.SuccessPrint('Script rechargé')
end)

-- ═══════════════════════════════════════════════════════════════
-- NETTOYAGE
-- ═══════════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    DeleteScharmanPed()
    DeleteScharmanBlip()
end)

Config.DebugPrint('Fichier client/ped.lua chargé avec succès')
