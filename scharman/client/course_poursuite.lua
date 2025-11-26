-- ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
-- ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
-- ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
-- ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
-- ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
-- CLIENT - MODE COURSE POURSUITE
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- VARIABLES LOCALES
-- ═══════════════════════════════════════════════════════════════

local inGame = false
local currentVehicle = nil
local instanceId = nil
local blockExitThread = nil
local zoneCheckThread = nil
local gameEndTime = nil
local botPed = nil
local botVehicle = nil

-- ═══════════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES
-- ═══════════════════════════════════════════════════════════════

-- Afficher une notification NUI personnalisée
local function ShowGameNotification(message, duration, notifType)
    SendNUIMessage({
        action = 'showNotification',
        data = {
            message = message,
            duration = duration or Config.CoursePoursuit.MessageDuration,
            type = notifType or 'info'
        }
    })
end

-- Charger un modèle
local function LoadModel(model)
    local modelHash = GetHashKey(model)
    
    if not IsModelValid(modelHash) then
        Config.ErrorPrint('Modèle invalide: ' .. model)
        return false
    end
    
    RequestModel(modelHash)
    
    local timeout = 0
    while not HasModelLoaded(modelHash) do
        Wait(100)
        timeout = timeout + 100
        
        if timeout >= 10000 then
            Config.ErrorPrint('Timeout lors du chargement du modèle: ' .. model)
            return false
        end
    end
    
    Config.DebugPrint('Modèle chargé: ' .. model)
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- FONCTIONS BOT ADVERSAIRE
-- ═══════════════════════════════════════════════════════════════

-- Supprimer le bot
local function DeleteBot()
    if DoesEntityExist(botVehicle) then
        DeleteEntity(botVehicle)
        botVehicle = nil
        Config.DebugPrint('Véhicule bot supprimé')
    end
    
    if DoesEntityExist(botPed) then
        DeleteEntity(botPed)
        botPed = nil
        Config.DebugPrint('Bot supprimé')
    end
end

-- Spawner un bot adversaire
local function SpawnBotAdversary()
    if not Config.CoursePoursuit.SpawnBotInSolo then
        Config.DebugPrint('Spawn bot désactivé dans la config')
        return
    end
    
    Config.InfoPrint('Spawn du bot adversaire...')
    
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local playerHeading = GetEntityHeading(ped)
    
    -- Calculer la position du bot (à côté du joueur)
    local offset = Config.CoursePoursuit.BotSpawnOffset
    local forwardX = math.cos(math.rad(playerHeading))
    local forwardY = math.sin(math.rad(playerHeading))
    
    local botCoords = vector3(
        playerCoords.x + (forwardX * offset.x) + offset.y,
        playerCoords.y + (forwardY * offset.x),
        playerCoords.z + offset.z
    )
    
    -- Charger le modèle du bot
    if not LoadModel(Config.CoursePoursuit.BotModel) then
        Config.ErrorPrint('Échec chargement modèle bot')
        return
    end
    
    -- Créer le bot
    botPed = CreatePed(4, GetHashKey(Config.CoursePoursuit.BotModel), botCoords.x, botCoords.y, botCoords.z, playerHeading, true, false)
    
    if not DoesEntityExist(botPed) then
        Config.ErrorPrint('Échec création bot')
        return
    end
    
    Config.DebugPrint('Bot créé: ' .. botPed)
    
    -- Rendre le bot invincible
    SetEntityInvincible(botPed, true)
    SetBlockingOfNonTemporaryEvents(botPed, true)
    
    -- Charger le modèle du véhicule bot
    if not LoadModel(Config.CoursePoursuit.BotVehicle) then
        Config.ErrorPrint('Échec chargement véhicule bot')
        DeleteEntity(botPed)
        botPed = nil
        return
    end
    
    -- Créer le véhicule du bot
    botVehicle = CreateVehicle(
        GetHashKey(Config.CoursePoursuit.BotVehicle),
        botCoords.x,
        botCoords.y,
        botCoords.z,
        playerHeading,
        true,
        false
    )
    
    if not DoesEntityExist(botVehicle) then
        Config.ErrorPrint('Échec création véhicule bot')
        DeleteEntity(botPed)
        botPed = nil
        return
    end
    
    Config.DebugPrint('Véhicule bot créé: ' .. botVehicle)
    
    -- Personnaliser le véhicule bot
    local botColor = Config.CoursePoursuit.BotVehicleColor
    SetVehicleCustomPrimaryColour(botVehicle, botColor.primary.r, botColor.primary.g, botColor.primary.b)
    SetVehicleCustomSecondaryColour(botVehicle, botColor.secondary.r, botColor.secondary.g, botColor.secondary.b)
    SetVehicleNumberPlateText(botVehicle, 'BOT~AI')
    
    -- Rendre le véhicule plus résistant
    SetVehicleEngineHealth(botVehicle, 1000.0)
    SetVehicleBodyHealth(botVehicle, 1000.0)
    
    -- Attendre que le véhicule soit bien chargé
    Wait(500)
    
    -- Mettre le bot dans le véhicule
    TaskWarpPedIntoVehicle(botPed, botVehicle, -1)
    
    -- Attendre que le bot soit dans le véhicule
    Wait(1000)
    
    -- Faire conduire le bot
    if Config.CoursePoursuit.BotRandomRoute then
        TaskVehicleDriveWander(
            botPed,
            botVehicle,
            Config.CoursePoursuit.BotSpeed,
            Config.CoursePoursuit.BotDrivingStyle
        )
        Config.DebugPrint('Bot en conduite aléatoire')
    else
        -- Conduire vers un point lointain
        local targetCoords = vector3(
            botCoords.x + 500.0,
            botCoords.y + 500.0,
            botCoords.z
        )
        TaskVehicleDriveToCoordLongrange(
            botPed,
            botVehicle,
            targetCoords.x,
            targetCoords.y,
            targetCoords.z,
            Config.CoursePoursuit.BotSpeed,
            Config.CoursePoursuit.BotDrivingStyle,
            10.0
        )
        Config.DebugPrint('Bot en conduite vers point précis')
    end
    
    -- Libérer les modèles
    SetModelAsNoLongerNeeded(GetHashKey(Config.CoursePoursuit.BotModel))
    SetModelAsNoLongerNeeded(GetHashKey(Config.CoursePoursuit.BotVehicle))
    
    Config.SuccessPrint('Bot adversaire spawné et en conduite!')
    ShowGameNotification('🤖 Un adversaire bot est apparu !', 4000, 'success')
end

-- ═══════════════════════════════════════════════════════════════
-- DÉMARRAGE DU JEU
-- ═══════════════════════════════════════════════════════════════

-- Démarrer le jeu
local function StartCoursePoursuiteGame(data)
    if inGame then
        Config.DebugPrint('Déjà en jeu')
        return
    end
    
    -- Protection contre écran noir avec pcall
    local success, err = pcall(function()
        Config.InfoPrint('Démarrage de la Course Poursuite...')
        
        local ped = PlayerPedId()
        instanceId = data.instanceId
        
        -- Récupérer les coordonnées et le modèle
        local spawnCoords = data.spawnCoords or Config.CoursePoursuit.SpawnCoords
        local vehicleModel = data.vehicleModel or Config.CoursePoursuit.VehicleModel
        
        -- Notification de téléportation
        ShowGameNotification(Config.CoursePoursuit.Notifications.teleporting, 2000, 'info')
        
        -- Fade out
        DoScreenFadeOut(800)
        while not IsScreenFadedOut() do
            Wait(10)
        end
        
        -- Téléporter le joueur
        SetEntityCoords(ped, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, true)
        SetEntityHeading(ped, spawnCoords.w)
        
        -- Attendre stabilisation
        Wait(500)
        
        -- Charger le modèle du véhicule
        if not LoadModel(vehicleModel) then
            error('Échec du chargement du modèle de véhicule')
        end
        
        -- Créer le véhicule
        currentVehicle = CreateVehicle(
            GetHashKey(vehicleModel),
            spawnCoords.x,
            spawnCoords.y,
            spawnCoords.z,
            spawnCoords.w,
            true,
            false
        )
        
        if not DoesEntityExist(currentVehicle) then
            error('Échec de la création du véhicule')
        end
        
        Config.DebugPrint('Véhicule créé: ' .. currentVehicle)
        
        -- Personnaliser le véhicule
        local primaryColor = Config.CoursePoursuit.VehicleCustomization.primaryColor
        local secondaryColor = Config.CoursePoursuit.VehicleCustomization.secondaryColor
        SetVehicleCustomPrimaryColour(currentVehicle, primaryColor.r, primaryColor.g, primaryColor.b)
        SetVehicleCustomSecondaryColour(currentVehicle, secondaryColor.r, secondaryColor.g, secondaryColor.b)
        
        -- Appliquer les mods
        local mods = Config.CoursePoursuit.VehicleCustomization.mods
        SetVehicleMod(currentVehicle, 11, mods.engine, false)
        SetVehicleMod(currentVehicle, 12, mods.brakes, false)
        SetVehicleMod(currentVehicle, 13, mods.transmission, false)
        SetVehicleMod(currentVehicle, 15, mods.suspension, false)
        ToggleVehicleMod(currentVehicle, 18, mods.turbo)
        
        -- Plaque d'immatriculation
        SetVehicleNumberPlateText(currentVehicle, 'COURSE')
        
        -- Remplir essence
        SetVehicleFuelLevel(currentVehicle, 100.0)
        
        -- Santé du véhicule
        SetVehicleEngineHealth(currentVehicle, 1000.0)
        SetVehicleBodyHealth(currentVehicle, 1000.0)
        
        -- Verrouiller les portes pour empêcher les autres joueurs d'entrer
        SetVehicleDoorsLocked(currentVehicle, 2)
        SetVehicleDoorsLockedForAllPlayers(currentVehicle, true)
        
        -- Attendre que le véhicule soit bien créé
        Wait(500)
        
        -- Mettre le joueur dans le véhicule (siège conducteur)
        TaskWarpPedIntoVehicle(ped, currentVehicle, -1)
        Config.DebugPrint('Joueur placé dans le véhicule')
        
        -- Attendre que le joueur soit dans le véhicule
        Wait(1000)
        
        -- Vérifier que le joueur est bien dans le véhicule
        if GetVehiclePedIsIn(ped, false) ~= currentVehicle then
            Config.ErrorPrint('Le joueur n\'est pas dans le véhicule!')
            -- Réessayer
            TaskWarpPedIntoVehicle(ped, currentVehicle, -1)
            Wait(500)
        end
        
        -- Libérer le modèle
        SetModelAsNoLongerNeeded(GetHashKey(vehicleModel))
        
        -- Fade in
        DoScreenFadeIn(500)
        while not IsScreenFadedIn() do
            Wait(10)
        end
        
        -- Marquer comme en jeu
        inGame = true
        
        -- Notification de démarrage
        ShowGameNotification(Config.CoursePoursuit.Notifications.starting, 3000, 'info')
        Wait(3000)
        ShowGameNotification(Config.CoursePoursuit.Notifications.started, 3000, 'success')
        
        -- Calculer l'heure de fin si durée définie
        if Config.CoursePoursuit.GameDuration > 0 then
            gameEndTime = GetGameTimer() + (Config.CoursePoursuit.GameDuration * 1000)
        end
        
        -- Spawner un bot si mode solo activé
        if data.spawnBot then
            Config.InfoPrint('Mode solo détecté, spawn du bot...')
            Wait(2000) -- Attendre 2 secondes pour que tout soit stable
            SpawnBotAdversary()
        end
        
        -- Démarrer les threads de gestion
        StartGameThreads()
        
        Config.SuccessPrint('Course Poursuite démarrée!')
    end)
    
    -- Si erreur, restaurer l'écran et nettoyer
    if not success then
        Config.ErrorPrint('ERREUR lors du démarrage: ' .. tostring(err))
        
        -- TOUJOURS faire le fade in pour éviter écran noir
        if IsScreenFadedOut() then
            DoScreenFadeIn(500)
        end
        
        -- Nettoyer
        if DoesEntityExist(currentVehicle) then
            DeleteEntity(currentVehicle)
            currentVehicle = nil
        end
        
        -- Notification d'erreur
        ShowGameNotification('❌ Erreur lors du démarrage: ' .. tostring(err), 5000, 'error')
        
        -- Prévenir le serveur
        TriggerServerEvent('scharman:server:coursePoursuiteLeft', instanceId)
        
        inGame = false
        instanceId = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ARRÊT DU JEU
-- ═══════════════════════════════════════════════════════════════

-- Arrêter le jeu
local function StopCoursePoursuiteGame()
    if not inGame then
        Config.DebugPrint('Pas en jeu')
        return
    end
    
    Config.InfoPrint('Arrêt du mode Course Poursuite, nettoyage...')
    
    -- Marquer comme pas en jeu
    inGame = false
    
    -- Arrêter les threads
    blockExitThread = nil
    zoneCheckThread = nil
    gameEndTime = nil
    
    local ped = PlayerPedId()
    
    -- Téléporter le joueur à la position de retour
    if Config.CoursePoursuit.ReturnToNormalCoords then
        DoScreenFadeOut(500)
        Wait(500)
        
        local returnCoords = Config.CoursePoursuit.ReturnToNormalCoords
        SetEntityCoords(ped, returnCoords.x, returnCoords.y, returnCoords.z, false, false, false, true)
        SetEntityHeading(ped, returnCoords.w)
        
        Wait(500)
        DoScreenFadeIn(500)
    end
    
    -- Supprimer le véhicule
    if DoesEntityExist(currentVehicle) then
        DeleteEntity(currentVehicle)
        currentVehicle = nil
        Config.DebugPrint('Véhicule supprimé')
    end
    
    -- Supprimer le bot
    DeleteBot()
    
    -- Réinitialiser instanceId
    instanceId = nil
    
    Config.SuccessPrint('Nettoyage terminé')
end

-- ═══════════════════════════════════════════════════════════════
-- THREADS DE GESTION
-- ═══════════════════════════════════════════════════════════════

-- Thread de blocage de sortie du véhicule
local function StartBlockExitThread()
    if blockExitThread then return end
    
    Config.DebugPrint('Thread de blocage de sortie démarré')
    
    blockExitThread = CreateThread(function()
        while inGame and Config.CoursePoursuit.BlockExitVehicle do
            Wait(0)
            
            local ped = PlayerPedId()
            
            -- Bloquer la touche F (sortir du véhicule)
            DisableControlAction(0, 75, true) -- INPUT_VEH_EXIT
            
            -- Si le joueur essaye de sortir
            if IsDisabledControlJustPressed(0, 75) then
                ShowGameNotification(Config.CoursePoursuit.BlockExitMessage, 3000, 'warning')
                Config.DebugPrint('Tentative de sortie bloquée')
            end
            
            -- Si le joueur est sorti (par un bug), le remettre dans le véhicule
            if DoesEntityExist(currentVehicle) and not IsPedInVehicle(ped, currentVehicle, false) then
                TaskWarpPedIntoVehicle(ped, currentVehicle, -1)
                ShowGameNotification('🚗 Retour forcé dans le véhicule !', 3000, 'warning')
                Config.DebugPrint('Joueur remis dans le véhicule')
            end
        end
        
        blockExitThread = nil
        Config.DebugPrint('Thread de blocage de sortie arrêté')
    end)
end

-- Thread de vérification de zone
local function StartZoneCheckThread()
    if not Config.CoursePoursuit.UseZoneLimit then return end
    if zoneCheckThread then return end
    
    Config.DebugPrint('Thread de vérification de zone démarré')
    
    zoneCheckThread = CreateThread(function()
        local timeOutOfZone = 0
        
        while inGame do
            Wait(1000) -- Vérifier chaque seconde
            
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)
            local zoneCenter = Config.CoursePoursuit.SpawnCoords
            local distance = #(playerCoords - vector3(zoneCenter.x, zoneCenter.y, zoneCenter.z))
            
            if distance > Config.CoursePoursuit.ZoneRadius then
                timeOutOfZone = timeOutOfZone + 1
                
                if timeOutOfZone == 1 then
                    ShowGameNotification('⚠️ Retournez dans la zone de jeu !', 3000, 'warning')
                end
                
                if timeOutOfZone >= Config.CoursePoursuit.OutOfZoneTimeout then
                    ShowGameNotification('🚫 Trop loin de la zone ! Téléportation...', 3000, 'error')
                    
                    -- Téléporter dans la zone
                    SetEntityCoords(ped, zoneCenter.x, zoneCenter.y, zoneCenter.z, false, false, false, true)
                    timeOutOfZone = 0
                end
            else
                timeOutOfZone = 0
            end
        end
        
        zoneCheckThread = nil
        Config.DebugPrint('Thread de vérification de zone arrêté')
    end)
end

-- Thread du timer de jeu
local function StartGameTimerThread()
    if Config.CoursePoursuit.GameDuration <= 0 then return end
    
    Config.DebugPrint('Thread timer de jeu démarré')
    
    CreateThread(function()
        while inGame and gameEndTime do
            Wait(1000) -- Vérifier chaque seconde
            
            local timeLeft = gameEndTime - GetGameTimer()
            
            if timeLeft <= 0 then
                ShowGameNotification('⏱️ Temps écoulé ! Fin de la partie.', 5000, 'info')
                StopCoursePoursuiteGame()
                TriggerServerEvent('scharman:server:coursePoursuiteLeft', instanceId)
                break
            end
        end
        
        Config.DebugPrint('Thread timer de jeu arrêté')
    end)
end

-- Démarrer tous les threads
function StartGameThreads()
    StartBlockExitThread()
    StartZoneCheckThread()
    StartGameTimerThread()
end

-- ═══════════════════════════════════════════════════════════════
-- ÉVÉNEMENTS
-- ═══════════════════════════════════════════════════════════════

-- Démarrer le jeu
RegisterNetEvent('scharman:client:startCoursePoursuit', function(data)
    StartCoursePoursuiteGame(data)
end)

-- Arrêter le jeu
RegisterNetEvent('scharman:client:stopCoursePoursuit', function()
    StopCoursePoursuiteGame()
end)

-- Notification
RegisterNetEvent('scharman:client:courseNotification', function(message, duration, notifType)
    ShowGameNotification(message, duration or 3000, notifType or 'info')
end)

-- ═══════════════════════════════════════════════════════════════
-- COMMANDES DEBUG
-- ═══════════════════════════════════════════════════════════════

if Config.Debug then
    RegisterCommand('course_stop', function()
        if inGame then
            StopCoursePoursuiteGame()
            TriggerServerEvent('scharman:server:coursePoursuiteLeft', instanceId)
            Config.InfoPrint('Course arrêtée manuellement')
        else
            Config.ErrorPrint('Tu n\'es pas en jeu')
        end
    end, false)
    
    RegisterCommand('course_info', function()
        print('═══════════════════════════════════════════════════════════════')
        print('État du jeu: ' .. (inGame and 'EN JEU' or 'PAS EN JEU'))
        print('Instance: ' .. (instanceId or 'Aucune'))
        print('Véhicule: ' .. (currentVehicle or 'Aucun'))
        print('Bot PED: ' .. (botPed or 'Aucun'))
        print('Bot Véhicule: ' .. (botVehicle or 'Aucun'))
        if gameEndTime then
            local timeLeft = gameEndTime - GetGameTimer()
            print('Temps restant: ' .. math.floor(timeLeft / 1000) .. 's')
        end
        print('═══════════════════════════════════════════════════════════════')
    end, false)
    
    Config.InfoPrint('Commandes de debug Course Poursuite disponibles')
    Config.InfoPrint('- /course_stop : Arrêter le jeu')
    Config.InfoPrint('- /course_info : Afficher les informations')
end

Config.DebugPrint('Fichier client/course_poursuite.lua chargé avec succès')
