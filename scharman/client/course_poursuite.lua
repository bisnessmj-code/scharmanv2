-- ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
-- ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
-- ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
-- ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
-- ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
-- CLIENT - MODE COURSE POURSUITE V2 (AMÉLIORÉ)
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- VARIABLES LOCALES
-- ═══════════════════════════════════════════════════════════════

local inGame = false
local currentVehicle = nil
local instanceId = nil
local currentBucket = 0 -- ✅ Bucket actuel du joueur
local blockExitThread = nil
local zoneCheckThread = nil
local gameEndTime = nil
local gameStartTime = nil
local botPed = nil
local botVehicle = nil

-- ✅ ZONE DE GUERRE - Spawn immédiat
local canExitVehicle = false
local warZoneActive = false
local warZonePosition = nil
local warZoneBlip = nil
local warZoneCenterBlip = nil
local warZoneThread = nil
local warZoneRadius = 50.0

-- ✅ DÉCOMPTE
local countdownActive = false

-- ═══════════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES
-- ═══════════════════════════════════════════════════════════════

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

local function LoadModel(model)
    local modelHash = GetHashKey(model)
    
    if not IsModelValid(modelHash) then
        Config.ErrorPrint('Modèle invalide: ' .. model)
        return false
    end
    
    Config.DebugPrint('Demande de chargement du modèle: ' .. model)
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
    
    Config.SuccessPrint('Modèle chargé: ' .. model)
    return true
end

local function ForcePlayerIntoVehicle(ped, vehicle, seat)
    Config.DebugPrint('Tentative de placement du joueur dans le véhicule...')
    
    if not DoesEntityExist(vehicle) then
        Config.ErrorPrint('Le véhicule n\'existe pas!')
        return false
    end
    
    if not DoesEntityExist(ped) then
        Config.ErrorPrint('Le PED n\'existe pas!')
        return false
    end
    
    SetVehicleOnGroundProperly(vehicle)
    Wait(100)
    
    Config.DebugPrint('État avant placement:')
    Config.DebugPrint('- Véhicule existe: ' .. tostring(DoesEntityExist(vehicle)))
    Config.DebugPrint('- PED existe: ' .. tostring(DoesEntityExist(ped)))
    Config.DebugPrint('- Siège: ' .. tostring(seat))
    
    TaskWarpPedIntoVehicle(ped, vehicle, seat)
    Wait(500)
    
    local attempts = 0
    local maxAttempts = 10
    
    while GetVehiclePedIsIn(ped, false) ~= vehicle and attempts < maxAttempts do
        attempts = attempts + 1
        Config.DebugPrint('Tentative ' .. attempts .. '/' .. maxAttempts .. ' de placement...')
        
        TaskWarpPedIntoVehicle(ped, vehicle, seat)
        Wait(300)
        
        if GetVehiclePedIsIn(ped, false) ~= vehicle then
            Config.DebugPrint('TaskWarp échoué, essai avec SetPedIntoVehicle...')
            SetPedIntoVehicle(ped, vehicle, seat)
            Wait(300)
        end
    end
    
    local currentVeh = GetVehiclePedIsIn(ped, false)
    local isInVehicle = currentVeh == vehicle
    
    Config.DebugPrint('État après placement:')
    Config.DebugPrint('- Véhicule actuel: ' .. tostring(currentVeh))
    Config.DebugPrint('- Véhicule cible: ' .. tostring(vehicle))
    Config.DebugPrint('- Dans le véhicule: ' .. tostring(isInVehicle))
    Config.DebugPrint('- Tentatives: ' .. attempts)
    
    if isInVehicle then
        Config.SuccessPrint('Joueur placé dans le véhicule avec succès!')
        return true
    else
        Config.ErrorPrint('ÉCHEC: Le joueur n\'est pas dans le véhicule après ' .. attempts .. ' tentatives')
        return false
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ZONE DE GUERRE
-- ═══════════════════════════════════════════════════════════════

-- ✅ CORRECTION: Déclarer StartWarZoneThread AVANT CreateWarZone
local function StartWarZoneThread()
    if warZoneThread then return end
    
    Config.InfoPrint('Thread de rendu zone de guerre démarré')
    
    warZoneThread = CreateThread(function()
        while inGame and warZoneActive do
            Wait(0)
            
            -- ✅ Vérifier que warZonePosition existe avant de l'utiliser
            if not warZonePosition then
                Wait(100)
                goto continue
            end
            
            local pos = warZonePosition
            
            -- Colonne de lumière rouge (cylindre vertical)
            DrawMarker(
                28,
                pos.x, pos.y, pos.z,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                warZoneRadius, warZoneRadius, 150.0,
                255, 0, 0, 100,
                false, false, 2, false, nil, nil, false
            )
            
            -- Cercle au sol
            DrawMarker(
                1,
                pos.x, pos.y, pos.z - 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                warZoneRadius * 2, warZoneRadius * 2, 1.0,
                255, 0, 0, 150,
                false, false, 2, false, nil, nil, false
            )
            
            ::continue::
        end
        
        warZoneThread = nil
        Config.DebugPrint('Thread de rendu zone de guerre arrêté')
    end)
end

local function CreateWarZone(position)
    Config.InfoPrint('🔴 CRÉATION ZONE DE GUERRE')
    
    warZonePosition = position
    warZoneActive = true
    
    -- Créer le blip de rayon (zone rouge)
    if warZoneBlip then
        RemoveBlip(warZoneBlip)
    end
    
    warZoneBlip = AddBlipForRadius(position.x, position.y, position.z, warZoneRadius)
    SetBlipHighDetail(warZoneBlip, true)
    SetBlipColour(warZoneBlip, 1) -- Rouge
    SetBlipAlpha(warZoneBlip, 180)
    
    -- Créer le blip centre (crâne)
    if warZoneCenterBlip then
        RemoveBlip(warZoneCenterBlip)
    end
    
    warZoneCenterBlip = AddBlipForCoord(position.x, position.y, position.z)
    SetBlipSprite(warZoneCenterBlip, 84) -- Crâne
    SetBlipDisplay(warZoneCenterBlip, 4)
    SetBlipScale(warZoneCenterBlip, 1.2)
    SetBlipColour(warZoneCenterBlip, 1) -- Rouge
    SetBlipAsShortRange(warZoneCenterBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("🔴 ZONE DE GUERRE")
    EndTextCommandSetBlipName(warZoneCenterBlip)
    
    Config.SuccessPrint('Zone de guerre créée à la position: ' .. tostring(position))
    
    -- Démarrer le thread de rendu
    StartWarZoneThread()
end

local function DeleteWarZone()
    Config.DebugPrint('Suppression de la zone de guerre...')
    
    warZoneActive = false
    warZonePosition = nil
    
    if warZoneBlip then
        RemoveBlip(warZoneBlip)
        warZoneBlip = nil
    end
    
    if warZoneCenterBlip then
        RemoveBlip(warZoneCenterBlip)
        warZoneCenterBlip = nil
    end
    
    if warZoneThread then
        warZoneThread = nil
    end
    
    Config.SuccessPrint('Zone de guerre supprimée')
end

-- ═══════════════════════════════════════════════════════════════
-- DÉCOMPTE 3-2-1-GO
-- ═══════════════════════════════════════════════════════════════

local function StartCountdown()
    Config.InfoPrint('⏱️ DÉMARRAGE DU DÉCOMPTE')
    
    countdownActive = true
    
    -- Bloquer les contrôles pendant le décompte
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    
    -- 3
    SendNUIMessage({
        action = 'showCountdown',
        data = { number = 3 }
    })
    PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
    Wait(1000)
    
    -- 2
    SendNUIMessage({
        action = 'showCountdown',
        data = { number = 2 }
    })
    PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
    Wait(1000)
    
    -- 1
    SendNUIMessage({
        action = 'showCountdown',
        data = { number = 1 }
    })
    PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
    Wait(1000)
    
    -- GO!
    SendNUIMessage({
        action = 'showCountdown',
        data = { number = 'GO!' }
    })
    PlaySoundFrontend(-1, 'RACE_PLACED', 'HUD_AWARDS', true)
    
    -- Débloquer
    FreezeEntityPosition(ped, false)
    
    Wait(1000)
    
    -- Cacher le décompte
    SendNUIMessage({
        action = 'hideCountdown'
    })
    
    countdownActive = false
    Config.SuccessPrint('✅ Décompte terminé - C\'EST PARTI!')
end

-- ═══════════════════════════════════════════════════════════════
-- FONCTIONS BOT
-- ═══════════════════════════════════════════════════════════════

local function DeleteBot()
    Config.DebugPrint('Suppression du bot...')
    
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
    
    Config.SuccessPrint('Bot nettoyé')
end

local function SpawnBotAdversary()
    if not Config.CoursePoursuit.SpawnBotInSolo then
        Config.DebugPrint('Spawn bot désactivé dans la config')
        return false
    end
    
    Config.InfoPrint('═══ DÉBUT SPAWN BOT ═══')
    
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local playerHeading = GetEntityHeading(ped)
    
    local offset = Config.CoursePoursuit.BotSpawnOffset
    local forwardX = math.cos(math.rad(playerHeading))
    local forwardY = math.sin(math.rad(playerHeading))
    
    local botCoords = vector3(
        playerCoords.x + (forwardX * offset.x) + offset.y,
        playerCoords.y + (forwardY * offset.x),
        playerCoords.z + offset.z
    )
    
    if not LoadModel(Config.CoursePoursuit.BotModel) then
        Config.ErrorPrint('Échec chargement modèle bot')
        return false
    end
    
    Config.DebugPrint('Création du bot PED...')
    Config.DebugPrint('Position: ' .. tostring(botCoords))
    Config.DebugPrint('Bucket: ' .. tostring(currentBucket))
    
    botPed = CreatePed(4, GetHashKey(Config.CoursePoursuit.BotModel), botCoords.x, botCoords.y, botCoords.z, playerHeading, true, true)
    
    Config.DebugPrint('CreatePed retourné: ' .. tostring(botPed))
    
    Wait(1000) -- ✅ Augmenté à 1 seconde pour donner le temps au PED de spawn
    
    if not botPed or botPed == 0 or not DoesEntityExist(botPed) then
        Config.ErrorPrint('Échec création bot PED (Entity ID: ' .. tostring(botPed) .. ')')
        SetModelAsNoLongerNeeded(GetHashKey(Config.CoursePoursuit.BotModel))
        return false
    end
    
    Config.SuccessPrint('Bot PED entity créé (ID: ' .. botPed .. ')')
    
    -- ✅ Mettre le bot dans le même routing bucket que le joueur
    if currentBucket > 0 then
        SetEntityRoutingBucket(botPed, currentBucket)
        Wait(200) -- Attendre que le bucket soit appliqué
        Config.SuccessPrint('Bot PED placé dans bucket ' .. currentBucket)
    else
        Config.ErrorPrint('Bucket invalide ou non défini: ' .. tostring(currentBucket))
    end
    
    SetEntityInvincible(botPed, true)
    SetBlockingOfNonTemporaryEvents(botPed, true)
    Config.SuccessPrint('Bot PED créé')
    
    if not LoadModel(Config.CoursePoursuit.BotVehicle) then
        Config.ErrorPrint('Échec chargement véhicule bot')
        DeleteEntity(botPed)
        botPed = nil
        return false
    end
    
    Config.DebugPrint('Création du véhicule bot...')
    
    botVehicle = CreateVehicle(
        GetHashKey(Config.CoursePoursuit.BotVehicle),
        botCoords.x, botCoords.y, botCoords.z,
        playerHeading, true, true
    )
    
    Config.DebugPrint('CreateVehicle retourné: ' .. tostring(botVehicle))
    
    Wait(1000) -- ✅ Augmenté à 1 seconde
    
    if not botVehicle or botVehicle == 0 or not DoesEntityExist(botVehicle) then
        Config.ErrorPrint('Échec création véhicule bot (Entity ID: ' .. tostring(botVehicle) .. ')')
        DeleteEntity(botPed)
        botPed = nil
        SetModelAsNoLongerNeeded(GetHashKey(Config.CoursePoursuit.BotVehicle))
        return false
    end
    
    Config.SuccessPrint('Véhicule bot entity créé (ID: ' .. botVehicle .. ')')
    
    -- ✅ Mettre le véhicule bot dans le même routing bucket
    if currentBucket > 0 then
        SetEntityRoutingBucket(botVehicle, currentBucket)
        Wait(200) -- Attendre que le bucket soit appliqué
        Config.SuccessPrint('Véhicule bot placé dans bucket ' .. currentBucket)
    else
        Config.ErrorPrint('Bucket invalide pour véhicule bot: ' .. tostring(currentBucket))
    end
    
    Config.SuccessPrint('Véhicule bot créé')
    
    local botColor = Config.CoursePoursuit.BotVehicleColor
    SetVehicleCustomPrimaryColour(botVehicle, botColor.primary.r, botColor.primary.g, botColor.primary.b)
    SetVehicleCustomSecondaryColour(botVehicle, botColor.secondary.r, botColor.secondary.g, botColor.secondary.b)
    SetVehicleNumberPlateText(botVehicle, 'BOT~AI')
    SetVehicleEngineHealth(botVehicle, 1000.0)
    SetVehicleBodyHealth(botVehicle, 1000.0)
    SetVehicleOnGroundProperly(botVehicle)
    
    Wait(1000)
    
    TaskWarpPedIntoVehicle(botPed, botVehicle, -1)
    Wait(1000)
    
    local attempts = 0
    local maxAttempts = 5
    
    while GetVehiclePedIsIn(botPed, false) ~= botVehicle and attempts < maxAttempts do
        attempts = attempts + 1
        TaskWarpPedIntoVehicle(botPed, botVehicle, -1)
        Wait(500)
        
        if GetVehiclePedIsIn(botPed, false) ~= botVehicle then
            SetPedIntoVehicle(botPed, botVehicle, -1)
            Wait(500)
        end
    end
    
    if GetVehiclePedIsIn(botPed, false) ~= botVehicle then
        Config.ErrorPrint('ÉCHEC: Bot pas dans le véhicule!')
        DeleteBot()
        return false
    end
    
    if Config.CoursePoursuit.BotRandomRoute then
        TaskVehicleDriveWander(botPed, botVehicle, Config.CoursePoursuit.BotSpeed, Config.CoursePoursuit.BotDrivingStyle)
    else
        local targetCoords = vector3(botCoords.x + 500.0, botCoords.y + 500.0, botCoords.z)
        TaskVehicleDriveToCoordLongrange(botPed, botVehicle, targetCoords.x, targetCoords.y, targetCoords.z, Config.CoursePoursuit.BotSpeed, Config.CoursePoursuit.BotDrivingStyle, 10.0)
    end
    
    SetModelAsNoLongerNeeded(GetHashKey(Config.CoursePoursuit.BotModel))
    SetModelAsNoLongerNeeded(GetHashKey(Config.CoursePoursuit.BotVehicle))
    
    Config.InfoPrint('═══ FIN SPAWN BOT - SUCCÈS ═══')
    ShowGameNotification('🤖 Un adversaire bot est apparu !', 4000, 'success')
    
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- DÉMARRAGE DU JEU
-- ═══════════════════════════════════════════════════════════════

local function StartCoursePoursuiteGame(data)
    if inGame then
        Config.DebugPrint('Déjà en jeu')
        return
    end
    
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    Config.InfoPrint('DÉMARRAGE DE LA COURSE POURSUITE V2')
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    
    local success, err = pcall(function()
        local ped = PlayerPedId()
        instanceId = data.instanceId
        
        local spawnCoords = data.spawnCoords or Config.CoursePoursuit.SpawnCoords
        local vehicleModel = data.vehicleModel or Config.CoursePoursuit.VehicleModel
        
        ShowGameNotification(Config.CoursePoursuit.Notifications.teleporting, 2000, 'info')
        
        DoScreenFadeOut(800)
        while not IsScreenFadedOut() do Wait(10) end
        
        SetEntityCoords(ped, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, true)
        SetEntityHeading(ped, spawnCoords.w)
        
        local expectedBucket = data.bucketId
        currentBucket = expectedBucket or 0 -- ✅ Stocker le bucket
        if expectedBucket then
            Config.InfoPrint('Synchronisation routing bucket ' .. expectedBucket)
            Wait(3000)
            Config.SuccessPrint('Délai de synchronisation terminé')
        else
            Wait(3000)
        end
        
        Wait(1000)
        
        -- ✅ Récupération du véhicule créé par le serveur
        local vehicleNetId = data.vehicleNetId
        
        if vehicleNetId then
            Config.InfoPrint('═══ RÉCUPÉRATION VÉHICULE SERVEUR ═══')
            Config.DebugPrint('Vehicle Network ID reçu: ' .. vehicleNetId)
            
            local maxAttempts = 100
            local attempt = 0
            
            repeat
                currentVehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
                
                if currentVehicle and DoesEntityExist(currentVehicle) then
                    Config.SuccessPrint('Véhicule récupéré: ' .. currentVehicle)
                    break
                end
                
                attempt = attempt + 1
                Wait(100)
                
                if attempt % 10 == 0 then
                    Config.DebugPrint('Attente véhicule... ' .. attempt .. '/100')
                end
            until attempt >= maxAttempts
            
            if not currentVehicle or not DoesEntityExist(currentVehicle) then
                error('Échec récupération véhicule - NetID: ' .. vehicleNetId)
            end
            
            SetVehicleOnGroundProperly(currentVehicle)
            Wait(500)
            
        else
            Config.ErrorPrint('Pas de Network ID reçu - Fallback')
            
            if not LoadModel(vehicleModel) then
                error('Échec chargement modèle: ' .. vehicleModel)
            end
            
            currentVehicle = CreateVehicle(
                GetHashKey(vehicleModel),
                spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w,
                true, true
            )
            
            Wait(1500)
            
            if not DoesEntityExist(currentVehicle) then
                error('Échec création véhicule')
            end
            
            SetVehicleOnGroundProperly(currentVehicle)
            Wait(500)
        end
        
        -- Personnalisation
        if not vehicleNetId then
            local primaryColor = Config.CoursePoursuit.VehicleCustomization.primaryColor
            local secondaryColor = Config.CoursePoursuit.VehicleCustomization.secondaryColor
            SetVehicleCustomPrimaryColour(currentVehicle, primaryColor.r, primaryColor.g, primaryColor.b)
            SetVehicleCustomSecondaryColour(currentVehicle, secondaryColor.r, secondaryColor.g, secondaryColor.b)
            
            local mods = Config.CoursePoursuit.VehicleCustomization.mods
            SetVehicleMod(currentVehicle, 11, mods.engine, false)
            SetVehicleMod(currentVehicle, 12, mods.brakes, false)
            SetVehicleMod(currentVehicle, 13, mods.transmission, false)
            SetVehicleMod(currentVehicle, 15, mods.suspension, false)
            ToggleVehicleMod(currentVehicle, 18, mods.turbo)
            
            SetVehicleNumberPlateText(currentVehicle, 'COURSE')
            
            pcall(function()
                SetVehicleFuelLevel(currentVehicle, 100.0)
            end)
            
            SetVehicleEngineHealth(currentVehicle, 1000.0)
            SetVehicleBodyHealth(currentVehicle, 1000.0)
            SetVehicleDoorsLocked(currentVehicle, 2)
            SetVehicleDoorsLockedForAllPlayers(currentVehicle, true)
        else
            local primaryColor = Config.CoursePoursuit.VehicleCustomization.primaryColor
            local secondaryColor = Config.CoursePoursuit.VehicleCustomization.secondaryColor
            SetVehicleCustomPrimaryColour(currentVehicle, primaryColor.r, primaryColor.g, primaryColor.b)
            SetVehicleCustomSecondaryColour(currentVehicle, secondaryColor.r, secondaryColor.g, secondaryColor.b)
            
            local mods = Config.CoursePoursuit.VehicleCustomization.mods
            SetVehicleMod(currentVehicle, 11, mods.engine, false)
            SetVehicleMod(currentVehicle, 12, mods.brakes, false)
            SetVehicleMod(currentVehicle, 13, mods.transmission, false)
            SetVehicleMod(currentVehicle, 15, mods.suspension, false)
            ToggleVehicleMod(currentVehicle, 18, mods.turbo)
            
            SetVehicleNumberPlateText(currentVehicle, 'COURSE')
            
            pcall(function()
                SetVehicleFuelLevel(currentVehicle, 100.0)
            end)
            
            SetVehicleEngineHealth(currentVehicle, 1000.0)
            SetVehicleBodyHealth(currentVehicle, 1000.0)
            SetVehicleDoorsLocked(currentVehicle, 2)
            SetVehicleDoorsLockedForAllPlayers(currentVehicle, true)
            
            Config.SuccessPrint('Véhicule personnalisé côté client')
        end
        
        -- ✅ PLACEMENT JOUEUR
        Config.InfoPrint('═══ PLACEMENT JOUEUR ═══')
        local placementSuccess = ForcePlayerIntoVehicle(ped, currentVehicle, -1)
        
        if not placementSuccess then
            error('Impossible de placer le joueur dans le véhicule')
        end
        
        SetModelAsNoLongerNeeded(GetHashKey(vehicleModel))
        
        -- Fade in
        DoScreenFadeIn(500)
        while not IsScreenFadedIn() do Wait(10) end
        
        inGame = true
        gameStartTime = GetGameTimer()
        
        -- ✅ La zone sera créée quand le joueur SORT du véhicule
        Config.InfoPrint('Zone de guerre sera créée à votre première sortie')
        
        -- ✅ DÉCOMPTE 3-2-1-GO
        StartCountdown()
        
        -- Calculer fin de jeu
        if Config.CoursePoursuit.GameDuration > 0 then
            gameEndTime = GetGameTimer() + (Config.CoursePoursuit.GameDuration * 1000)
        end
        
        -- Spawner bot si solo
        if data.spawnBot then
            Config.InfoPrint('Mode solo - spawn bot dans 2s')
            Wait(2000)
            SpawnBotAdversary()
        end
        
        -- Démarrer threads
        StartGameThreads()
        
        Config.SuccessPrint('COURSE POURSUITE V2 DÉMARRÉE!')
    end)
    
    if not success then
        Config.ErrorPrint('ERREUR: ' .. tostring(err))
        
        if IsScreenFadedOut() then
            DoScreenFadeIn(500)
        end
        
        if DoesEntityExist(currentVehicle) then
            DeleteEntity(currentVehicle)
            currentVehicle = nil
        end
        
        DeleteBot()
        DeleteWarZone()
        
        ShowGameNotification('❌ Erreur: ' .. tostring(err), 5000, 'error')
        TriggerServerEvent('scharman:server:coursePoursuiteLeft', instanceId)
        
        inGame = false
        instanceId = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ARRÊT DU JEU
-- ═══════════════════════════════════════════════════════════════

local function StopCoursePoursuiteGame()
    if not inGame then return end
    
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    Config.InfoPrint('ARRÊT DU MODE COURSE POURSUITE V2')
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    
    inGame = false
    blockExitThread = nil
    zoneCheckThread = nil
    vehicleExitThread = nil -- ✅ Arrêter le thread de détection sortie
    damageZoneThread = nil -- ✅ Arrêter le thread de dégâts
    gameEndTime = nil
    gameStartTime = nil
    countdownActive = false
    canExitVehicle = false
    zoneCreatedOnExit = false -- ✅ Reset flag
    currentBucket = 0 -- ✅ Reset bucket
    
    -- ✅ Masquer l'écran de mort si affiché
    SendNUIMessage({
        action = 'hideDeathScreen'
    })
    
    -- ✅ SUPPRIMER LA ZONE DE GUERRE
    DeleteWarZone()
    
    local ped = PlayerPedId()
    
    -- Téléportation retour
    if Config.CoursePoursuit.ReturnToNormalCoords then
        DoScreenFadeOut(500)
        Wait(500)
        
        local returnCoords = Config.CoursePoursuit.ReturnToNormalCoords
        SetEntityCoords(ped, returnCoords.x, returnCoords.y, returnCoords.z, false, false, false, true)
        SetEntityHeading(ped, returnCoords.w)
        
        Wait(500)
        DoScreenFadeIn(500)
    end
    
    -- ✅ SUPPRIMER LE VÉHICULE
    if DoesEntityExist(currentVehicle) then
        DeleteEntity(currentVehicle)
        currentVehicle = nil
        Config.DebugPrint('Véhicule joueur supprimé')
    end
    
    -- ✅ SUPPRIMER LE BOT
    DeleteBot()
    
    instanceId = nil
    
    Config.SuccessPrint('NETTOYAGE TERMINÉ')
end

-- ═══════════════════════════════════════════════════════════════
-- THREADS DE GESTION
-- ═══════════════════════════════════════════════════════════════

local function StartBlockExitThread()
    if blockExitThread then return end
    
    Config.DebugPrint('Thread blocage sortie démarré')
    
    -- Timer 30 secondes
    CreateThread(function()
        -- Afficher le message de blocage
        SendNUIMessage({
            action = 'showVehicleLock',
            data = { duration = 30000 }
        })
        
        Wait(30000)
        
        canExitVehicle = true
        
        -- Masquer le message
        SendNUIMessage({
            action = 'hideVehicleLock'
        })
        
        Config.SuccessPrint('✅ Vous pouvez maintenant sortir du véhicule!')
        ShowGameNotification('✅ Vous pouvez maintenant sortir du véhicule!', 5000, 'success')
    end)
    
    blockExitThread = CreateThread(function()
        local wasInVehicle = true
        
        while inGame and Config.CoursePoursuit.BlockExitVehicle do
            Wait(0)
            
            local ped = PlayerPedId()
            local isInVehicle = IsPedInVehicle(ped, currentVehicle, false)
            
            if not canExitVehicle then
                DisableControlAction(0, 75, true)
                
                if IsDisabledControlJustPressed(0, 75) then
                    local timeElapsed = (GetGameTimer() - gameStartTime) / 1000
                    local timeLeft = math.max(0, 30 - timeElapsed)
                    ShowGameNotification(string.format('⏰ Attendez encore %d secondes!', math.ceil(timeLeft)), 3000, 'warning')
                end
                
                if DoesEntityExist(currentVehicle) and not isInVehicle then
                    ForcePlayerIntoVehicle(ped, currentVehicle, -1)
                    ShowGameNotification('🚗 Retour forcé - Attendez 30s', 3000, 'warning')
                end
            end
            
            wasInVehicle = isInVehicle
        end
        
        blockExitThread = nil
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- THREAD DÉGÂTS ZONE DE GUERRE
-- ═══════════════════════════════════════════════════════════════

local damageZoneThread = nil

local function StartDamageZoneThread()
    if damageZoneThread then return end
    
    Config.InfoPrint('Thread dégâts zone de guerre démarré')
    
    damageZoneThread = CreateThread(function()
        while inGame and warZoneActive do
            Wait(2000) -- Vérifier toutes les 2 secondes
            
            -- Attendre que la zone soit créée
            if not warZonePosition or not zoneCreatedOnExit then
                goto continue
            end
            
            local ped = PlayerPedId()
            
            -- Vérifier si le joueur est mort
            if IsEntityDead(ped) or GetEntityHealth(ped) <= 0 then
                Config.InfoPrint('💀 JOUEUR MORT DÉTECTÉ')
                
                -- Afficher écran de mort
                SendNUIMessage({
                    action = 'showDeathScreen'
                })
                
                Wait(3000) -- Attendre 3 secondes
                
                -- Terminer la partie
                StopCoursePoursuiteGame()
                TriggerServerEvent('scharman:server:coursePoursuiteLeft', instanceId)
                ShowGameNotification('💀 Vous êtes mort !', 3000, 'error')
                
                break
            end
            
            local playerCoords = GetEntityCoords(ped)
            local distance = #(playerCoords - warZonePosition)
            
            -- Si hors de la zone de guerre
            if distance > warZoneRadius then
                local currentHealth = GetEntityHealth(ped)
                local newHealth = currentHealth - 20
                
                Config.DebugPrint('⚡ DÉGÂTS ZONE: -20 HP (Health: ' .. currentHealth .. ' → ' .. newHealth .. ')')
                
                -- Infliger dégâts
                SetEntityHealth(ped, math.max(0, newHealth))
                
                -- Effet visuel
                SetPedToRagdoll(ped, 500, 500, 0, 0, 0, 0)
                
                -- Notification
                ShowGameNotification('⚡ DÉGÂTS ZONE: -20 HP', 1500, 'error')
                
                -- Vérifier si mort après dégâts
                if newHealth <= 0 then
                    Config.InfoPrint('💀 JOUEUR TUÉ PAR LA ZONE')
                    -- Le thread détectera la mort au prochain cycle
                end
            end
            
            ::continue::
        end
        
        damageZoneThread = nil
        Config.DebugPrint('Thread dégâts zone de guerre arrêté')
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- THREAD VÉRIFICATION ZONE (Téléportation)
-- ═══════════════════════════════════════════════════════════════

local function StartZoneCheckThread()
    if not Config.CoursePoursuit.UseZoneLimit then return end
    if zoneCheckThread then return end
    
    Config.DebugPrint('Thread vérification zone démarré')
    
    zoneCheckThread = CreateThread(function()
        local timeOutOfZone = 0
        
        while inGame do
            Wait(1000)
            
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)
            local zoneCenter = Config.CoursePoursuit.SpawnCoords
            local distance = #(playerCoords - vector3(zoneCenter.x, zoneCenter.y, zoneCenter.z))
            
            if distance > Config.CoursePoursuit.ZoneRadius then
                timeOutOfZone = timeOutOfZone + 1
                
                if timeOutOfZone == 1 then
                    ShowGameNotification('⚠️ Retournez dans la zone!', 3000, 'warning')
                end
                
                if timeOutOfZone >= Config.CoursePoursuit.OutOfZoneTimeout then
                    ShowGameNotification('🚫 Trop loin - Téléportation...', 3000, 'error')
                    SetEntityCoords(ped, zoneCenter.x, zoneCenter.y, zoneCenter.z, false, false, false, true)
                    timeOutOfZone = 0
                end
            else
                timeOutOfZone = 0
            end
        end
        
        zoneCheckThread = nil
    end)
end

local function StartGameTimerThread()
    if Config.CoursePoursuit.GameDuration <= 0 then return end
    
    CreateThread(function()
        while inGame and gameEndTime do
            Wait(1000)
            
            if not gameEndTime then break end
            
            local timeLeft = gameEndTime - GetGameTimer()
            
            if timeLeft <= 0 then
                ShowGameNotification('⏱️ Temps écoulé!', 5000, 'info')
                StopCoursePoursuiteGame()
                TriggerServerEvent('scharman:server:coursePoursuiteLeft', instanceId)
                break
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- DÉTECTION SORTIE VÉHICULE (Pour créer la zone)
-- ═══════════════════════════════════════════════════════════════

local vehicleExitThread = nil
local zoneCreatedOnExit = false

local function StartVehicleExitDetectionThread()
    if vehicleExitThread then return end
    
    zoneCreatedOnExit = false
    
    vehicleExitThread = CreateThread(function()
        Config.DebugPrint('Thread détection sortie véhicule démarré')
        
        while inGame and not zoneCreatedOnExit do
            Wait(500) -- Check toutes les 500ms
            
            local ped = PlayerPedId()
            
            -- Si le joueur peut sortir ET n'est PAS dans un véhicule
            if canExitVehicle and not IsPedInAnyVehicle(ped, false) then
                -- Créer la zone de guerre à la position actuelle
                local coords = GetEntityCoords(ped)
                CreateWarZone(coords)
                ShowGameNotification('🔴 ZONE DE GUERRE créée à votre position !', 5000, 'warning')
                
                -- ✅ DONNER L'ARME CAL50
                local weaponHash = GetHashKey('WEAPON_PISTOL50')
                GiveWeaponToPed(ped, weaponHash, 250, false, true)
                SetCurrentPedWeapon(ped, weaponHash, true)
                Config.SuccessPrint('Arme donnée: Pistolet Cal .50')
                ShowGameNotification('🔫 Pistolet Cal .50 équipé !', 3000, 'success')
                
                zoneCreatedOnExit = true
                Config.SuccessPrint('Zone de guerre créée à la sortie du véhicule')
                break
            end
        end
        
        vehicleExitThread = nil
        Config.DebugPrint('Thread détection sortie véhicule arrêté')
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- DÉMARRAGE DES THREADS
-- ═══════════════════════════════════════════════════════════════

function StartGameThreads()
    StartBlockExitThread()
    StartZoneCheckThread()
    StartGameTimerThread()
    StartVehicleExitDetectionThread()
    StartDamageZoneThread() -- ✅ Nouveau thread pour dégâts
end

-- ═══════════════════════════════════════════════════════════════
-- ÉVÉNEMENTS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('scharman:client:startCoursePoursuit', function(data)
    StartCoursePoursuiteGame(data)
end)

RegisterNetEvent('scharman:client:stopCoursePoursuit', function()
    StopCoursePoursuiteGame()
end)

RegisterNetEvent('scharman:client:courseNotification', function(message, duration, notifType)
    ShowGameNotification(message, duration or 3000, notifType or 'info')
end)

-- ═══════════════════════════════════════════════════════════════
-- COMMANDES
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('quit_course', function()
    if inGame then
        StopCoursePoursuiteGame()
        TriggerServerEvent('scharman:server:coursePoursuiteLeft', instanceId)
        ShowGameNotification('✅ Vous avez quitté', 3000, 'success')
    else
        ShowGameNotification('❌ Vous n\'êtes pas en partie', 3000, 'error')
    end
end, false)

if Config.Debug then
    RegisterCommand('course_stop', function()
        if inGame then
            StopCoursePoursuiteGame()
            TriggerServerEvent('scharman:server:coursePoursuiteLeft', instanceId)
        end
    end, false)
    
    RegisterCommand('course_info', function()
        print('═══════════════════════════════════════════════════════════════')
        print('État: ' .. (inGame and 'EN JEU' or 'PAS EN JEU'))
        print('Instance: ' .. (instanceId or 'Aucune'))
        print('Véhicule: ' .. (currentVehicle or 'Aucun'))
        print('Zone de guerre: ' .. (warZoneActive and 'ACTIVE' or 'INACTIVE'))
        print('Peut sortir véhicule: ' .. (canExitVehicle and 'OUI' or 'NON'))
        print('═══════════════════════════════════════════════════════════════')
    end, false)
end

Config.DebugPrint('client/course_poursuite.lua V2 chargé')
