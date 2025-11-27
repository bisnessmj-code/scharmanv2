-- ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
-- ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
-- ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
-- ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
-- ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
-- CLIENT - MODE COURSE POURSUITE V2 (CORRIGÉ)
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- VARIABLES LOCALES
-- ═══════════════════════════════════════════════════════════════

local inGame = false
local currentVehicle = nil
local instanceId = nil
local currentBucket = 0
local blockExitThread = nil
local zoneCheckThread = nil
local gameEndTime = nil
local gameStartTime = nil
local botPed = nil
local botVehicle = nil

-- ✅ ZONE DE GUERRE
local canExitVehicle = false
local warZoneActive = false
local warZonePosition = nil
local warZoneBlip = nil
local warZoneCenterBlip = nil
local warZoneThread = nil
local warZoneRadius = 50.0
local zoneCreatedOnExit = false -- ✅ CORRIGÉ: Variable globale

-- ✅ DÉCOMPTE
local countdownActive = false

-- ✅ NOUVEAUX: Pour gestion dégâts et mort
local damageZoneThread = nil
local vehicleExitThread = nil
local warningMessageActive = false

-- ═══════════════════════════════════════════════════════════════
-- FORWARD DECLARATIONS (Fonctions appelées avant leur définition)
-- ═══════════════════════════════════════════════════════════════

local StartDamageZoneThread  -- Déclaré ici, défini plus tard

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

local function StartWarZoneThread()
    if warZoneThread then return end
    
    Config.InfoPrint('Thread de rendu zone de guerre démarré')
    
    warZoneThread = CreateThread(function()
        while inGame and warZoneActive do
            Wait(0)
            
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
    Config.DebugPrint('[CREATE ZONE] Position: ' .. tostring(position))
    
    warZonePosition = position
    warZoneActive = true
    zoneCreatedOnExit = true -- ✅ IMPORTANT: Marquer la zone comme créée
    
    Config.DebugPrint('[CREATE ZONE] Variables mises à jour:')
    Config.DebugPrint('[CREATE ZONE] - warZonePosition: ' .. tostring(warZonePosition))
    Config.DebugPrint('[CREATE ZONE] - warZoneActive: ' .. tostring(warZoneActive))
    Config.DebugPrint('[CREATE ZONE] - zoneCreatedOnExit: ' .. tostring(zoneCreatedOnExit))
    
    -- Créer le blip de rayon (zone rouge)
    if warZoneBlip then
        RemoveBlip(warZoneBlip)
    end
    
    warZoneBlip = AddBlipForRadius(position.x, position.y, position.z, warZoneRadius)
    SetBlipHighDetail(warZoneBlip, true)
    SetBlipColour(warZoneBlip, 1) -- Rouge
    SetBlipAlpha(warZoneBlip, 180)
    
    Config.DebugPrint('[CREATE ZONE] Blip rayon créé')
    
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
    
    Config.DebugPrint('[CREATE ZONE] Blip centre créé')
    
    Config.SuccessPrint('Zone de guerre créée à la position: ' .. tostring(position))
    Config.InfoPrint('[CREATE ZONE] Rayon: ' .. warZoneRadius .. 'm')
    
    -- Démarrer le thread de rendu
    StartWarZoneThread()
    
    -- ✅ NOUVEAU: Faire que le bot se dirige vers la zone de guerre
    if botPed and DoesEntityExist(botPed) and botVehicle and DoesEntityExist(botVehicle) then
        Config.InfoPrint('[CREATE ZONE] 🤖 Redirection bot vers zone de guerre')
        
        -- Arrêter l'ancienne tâche
        ClearPedTasks(botPed)
        
        -- Diriger le bot vers le centre de la zone
        TaskVehicleDriveToCoordLongrange(
            botPed, 
            botVehicle, 
            position.x, 
            position.y, 
            position.z, 
            Config.CoursePoursuit.BotSpeed, 
            Config.CoursePoursuit.BotDrivingStyle, 
            20.0  -- Distance d'arrêt
        )
        
        Config.SuccessPrint('[CREATE ZONE] ✅ Bot va maintenant vers la zone !')
    end
    
    -- ✅ CORRECTION CRITIQUE: Démarrer le thread de dégâts MAINTENANT que la zone existe
    Config.InfoPrint('[CREATE ZONE] Démarrage thread dégâts zone...')
    StartDamageZoneThread()
end

local function DeleteWarZone()
    Config.DebugPrint('Suppression de la zone de guerre...')
    
    warZoneActive = false
    warZonePosition = nil
    zoneCreatedOnExit = false
    
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
-- FONCTIONS BOT (CORRIGÉ)
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
        Config.DebugPrint('[BOT] Spawn désactivé dans config')
        return false
    end
    
    Config.InfoPrint('╔═══════════════════════════════════════╗')
    Config.InfoPrint('║     DÉBUT SPAWN BOT ADVERSAIRE        ║')
    Config.InfoPrint('╚═══════════════════════════════════════╝')
    
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local playerHeading = GetEntityHeading(ped)
    
    -- ✅ Vérification bucket
    Config.DebugPrint('[BOT] ÉTAPE 1/12: Vérification bucket')
    if currentBucket == 0 then
        Config.ErrorPrint('[BOT] ❌ Bucket invalide (0) - Attente...')
        Wait(2000)
        if currentBucket == 0 then
            Config.ErrorPrint('[BOT] ❌ Bucket toujours invalide - ANNULATION')
            return false
        end
    end
    Config.SuccessPrint('[BOT] ✅ Bucket valide: ' .. currentBucket)
    
    -- ✅ Calcul position spawn
    Config.DebugPrint('[BOT] ÉTAPE 2/12: Calcul position spawn')
    local offset = Config.CoursePoursuit.BotSpawnOffset
    local forwardX = math.cos(math.rad(playerHeading))
    local forwardY = math.sin(math.rad(playerHeading))
    
    local botCoords = vector3(
        playerCoords.x + (forwardX * offset.x) + offset.y,
        playerCoords.y + (forwardY * offset.x),
        playerCoords.z + offset.z
    )
    Config.DebugPrint('[BOT] Position calculée: ' .. tostring(botCoords))
    
    -- ✅ Chargement modèle PED
    Config.DebugPrint('[BOT] ÉTAPE 3/12: Chargement modèle PED')
    Config.DebugPrint('[BOT] Modèle demandé: ' .. Config.CoursePoursuit.BotModel)
    
    if not LoadModel(Config.CoursePoursuit.BotModel) then
        Config.ErrorPrint('[BOT] ❌ Échec chargement modèle')
        return false
    end
    Config.SuccessPrint('[BOT] ✅ Modèle chargé')
    
    local modelHash = GetHashKey(Config.CoursePoursuit.BotModel)
    Config.DebugPrint('[BOT] Hash modèle: ' .. tostring(modelHash))
    Config.DebugPrint('[BOT] Modèle valide: ' .. tostring(IsModelValid(modelHash)))
    Config.DebugPrint('[BOT] Modèle dans mémoire: ' .. tostring(IsModelInCdimage(modelHash)))
    
    -- ✅ CRITIQUE: Désactiver la population pour forcer le spawn
    Config.DebugPrint('[BOT] ÉTAPE 4/12: Désactivation population temporaire')
    SetPedPopulationBudget(0)
    SetVehiclePopulationBudget(0)
    Config.DebugPrint('[BOT] Population désactivée')
    
    Wait(500)
    
    -- ✅ Création PED en LOCAL (pas networked)
    Config.DebugPrint('[BOT] ÉTAPE 5/12: Création PED LOCAL')
    Config.DebugPrint('[BOT] Paramètres:')
    Config.DebugPrint('[BOT] - Type: 4 (PED_TYPE_CIVMALE)')
    Config.DebugPrint('[BOT] - Hash: ' .. modelHash)
    Config.DebugPrint('[BOT] - X: ' .. botCoords.x)
    Config.DebugPrint('[BOT] - Y: ' .. botCoords.y)
    Config.DebugPrint('[BOT] - Z: ' .. botCoords.z)
    Config.DebugPrint('[BOT] - Heading: ' .. playerHeading)
    Config.DebugPrint('[BOT] - Network: false (LOCAL)')
    Config.DebugPrint('[BOT] - Mission: false')
    
    -- ✅ Créer en LOCAL pour éviter les problèmes de réseau
    botPed = CreatePed(4, modelHash, botCoords.x, botCoords.y, botCoords.z, playerHeading, false, false)
    
    Config.DebugPrint('[BOT] CreatePed() retourné: ' .. tostring(botPed))
    Config.DebugPrint('[BOT] Type retourné: ' .. type(botPed))
    
    if botPed == 0 or botPed == nil then
        Config.ErrorPrint('[BOT] ❌ CreatePed a retourné 0 ou nil!')
        SetPedPopulationBudget(3)
        SetVehiclePopulationBudget(3)
        SetModelAsNoLongerNeeded(modelHash)
        return false
    end
    
    -- ✅ Attente création avec vérifications ultra-détaillées
    Config.DebugPrint('[BOT] ÉTAPE 6/12: Attente création PED (max 10s)')
    
    local attempts = 0
    local maxAttempts = 50 -- 50 × 200ms = 10 secondes
    local pedExists = false
    
    while attempts < maxAttempts do
        Wait(200)
        attempts = attempts + 1
        
        pedExists = DoesEntityExist(botPed)
        
        -- Log détaillé tous les 5 essais
        if attempts % 5 == 0 then
            Config.DebugPrint(string.format('[BOT] Tentative %d/%d:', attempts, maxAttempts))
            Config.DebugPrint('[BOT]   DoesEntityExist: ' .. tostring(pedExists))
            Config.DebugPrint('[BOT]   IsEntityAPed: ' .. tostring(IsEntityAPed(botPed)))
            Config.DebugPrint('[BOT]   GetEntityType: ' .. tostring(GetEntityType(botPed)))
            
            if pedExists then
                local coords = GetEntityCoords(botPed)
                Config.DebugPrint('[BOT]   Position: ' .. tostring(coords))
                Config.DebugPrint('[BOT]   Health: ' .. tostring(GetEntityHealth(botPed)))
            end
        end
        
        if pedExists then
            Config.SuccessPrint(string.format('[BOT] ✅ PED existe après %.1fs (%d tentatives)', attempts * 0.2, attempts))
            break
        end
    end
    
    -- ✅ Réactiver la population
    Config.DebugPrint('[BOT] ÉTAPE 7/12: Réactivation population')
    SetPedPopulationBudget(3)
    SetVehiclePopulationBudget(3)
    Config.DebugPrint('[BOT] Population réactivée')
    
    if not pedExists then
        Config.ErrorPrint('[BOT] ❌ ÉCHEC CRITIQUE: PED n\'existe pas après 10 secondes!')
        Config.ErrorPrint('[BOT] Détails:')
        Config.ErrorPrint('[BOT]   Entity ID: ' .. tostring(botPed))
        Config.ErrorPrint('[BOT]   DoesEntityExist: ' .. tostring(DoesEntityExist(botPed)))
        Config.ErrorPrint('[BOT]   IsEntityAPed: ' .. tostring(IsEntityAPed(botPed)))
        Config.ErrorPrint('[BOT]   GetEntityType: ' .. tostring(GetEntityType(botPed)))
        
        DeleteEntity(botPed)
        botPed = nil
        SetModelAsNoLongerNeeded(modelHash)
        return false
    end
    
    Config.SuccessPrint('[BOT] ✅ PED créé avec succès (ID: ' .. botPed .. ')')
    
    -- ✅ Configuration PED
    Config.DebugPrint('[BOT] ÉTAPE 8/12: Configuration PED')
    
    -- ⚠️ IMPORTANT: SetEntityRoutingBucket() est SERVEUR uniquement !
    -- Le bot LOCAL hérite automatiquement du bucket du joueur
    Config.DebugPrint('[BOT] Note: Bot LOCAL hérite du bucket joueur (' .. currentBucket .. ') automatiquement')
    
    SetEntityInvincible(botPed, true)
    SetBlockingOfNonTemporaryEvents(botPed, true)
    SetPedCanRagdoll(botPed, false)
    SetPedFleeAttributes(botPed, 0, false)
    SetPedCombatAttributes(botPed, 17, true)
    
    Wait(500)
    
    Config.SuccessPrint('[BOT] ✅ PED configuré (invincible, no ragdoll, bucket ' .. currentBucket .. ')')
    
    -- ✅ Chargement modèle véhicule
    Config.DebugPrint('[BOT] ÉTAPE 9/12: Chargement modèle véhicule')
    Config.DebugPrint('[BOT] Modèle véhicule: ' .. Config.CoursePoursuit.BotVehicle)
    
    if not LoadModel(Config.CoursePoursuit.BotVehicle) then
        Config.ErrorPrint('[BOT] ❌ Échec chargement modèle véhicule')
        DeleteEntity(botPed)
        botPed = nil
        return false
    end
    Config.SuccessPrint('[BOT] ✅ Modèle véhicule chargé')
    
    local vehicleHash = GetHashKey(Config.CoursePoursuit.BotVehicle)
    Config.DebugPrint('[BOT] Hash véhicule: ' .. tostring(vehicleHash))
    
    -- ✅ Désactiver population à nouveau
    SetVehiclePopulationBudget(0)
    Wait(300)
    
    -- ✅ Création véhicule en LOCAL
    Config.DebugPrint('[BOT] ÉTAPE 10/12: Création véhicule LOCAL')
    botVehicle = CreateVehicle(vehicleHash, botCoords.x, botCoords.y, botCoords.z, playerHeading, false, false)
    
    Config.DebugPrint('[BOT] CreateVehicle() retourné: ' .. tostring(botVehicle))
    
    if botVehicle == 0 or botVehicle == nil then
        Config.ErrorPrint('[BOT] ❌ CreateVehicle a retourné 0 ou nil!')
        SetVehiclePopulationBudget(3)
        DeleteEntity(botPed)
        botPed = nil
        SetModelAsNoLongerNeeded(vehicleHash)
        return false
    end
    
    -- ✅ Attente création véhicule
    Config.DebugPrint('[BOT] Attente création véhicule (max 10s)')
    
    attempts = 0
    maxAttempts = 50
    local vehicleExists = false
    
    while attempts < maxAttempts do
        Wait(200)
        attempts = attempts + 1
        
        vehicleExists = DoesEntityExist(botVehicle)
        
        if attempts % 5 == 0 then
            Config.DebugPrint(string.format('[BOT] Tentative %d/%d:', attempts, maxAttempts))
            Config.DebugPrint('[BOT]   DoesEntityExist: ' .. tostring(vehicleExists))
            Config.DebugPrint('[BOT]   IsEntityAVehicle: ' .. tostring(IsEntityAVehicle(botVehicle)))
            
            if vehicleExists then
                local coords = GetEntityCoords(botVehicle)
                Config.DebugPrint('[BOT]   Position: ' .. tostring(coords))
            end
        end
        
        if vehicleExists then
            Config.SuccessPrint(string.format('[BOT] ✅ Véhicule existe après %.1fs (%d tentatives)', attempts * 0.2, attempts))
            break
        end
    end
    
    -- ✅ Réactiver population
    SetVehiclePopulationBudget(3)
    
    if not vehicleExists then
        Config.ErrorPrint('[BOT] ❌ ÉCHEC: Véhicule n\'existe pas après 10 secondes!')
        Config.ErrorPrint('[BOT] Entity ID: ' .. tostring(botVehicle))
        DeleteEntity(botPed)
        botPed = nil
        DeleteEntity(botVehicle)
        botVehicle = nil
        SetModelAsNoLongerNeeded(vehicleHash)
        return false
    end
    
    Config.SuccessPrint('[BOT] ✅ Véhicule créé (ID: ' .. botVehicle .. ')')
    
    -- ✅ Configuration véhicule
    Config.DebugPrint('[BOT] Configuration véhicule...')
    
    -- ⚠️ IMPORTANT: SetEntityRoutingBucket() est SERVEUR uniquement !
    -- Le véhicule LOCAL hérite automatiquement du bucket du joueur
    Config.DebugPrint('[BOT] Note: Véhicule LOCAL hérite du bucket joueur (' .. currentBucket .. ') automatiquement')
    
    local botColor = Config.CoursePoursuit.BotVehicleColor
    SetVehicleCustomPrimaryColour(botVehicle, botColor.primary.r, botColor.primary.g, botColor.primary.b)
    SetVehicleCustomSecondaryColour(botVehicle, botColor.secondary.r, botColor.secondary.g, botColor.secondary.b)
    SetVehicleNumberPlateText(botVehicle, 'BOT~AI')
    SetVehicleEngineHealth(botVehicle, 1000.0)
    SetVehicleBodyHealth(botVehicle, 1000.0)
    SetVehicleOnGroundProperly(botVehicle)
    
    Wait(1000)
    
    Config.SuccessPrint('[BOT] ✅ Véhicule configuré')
    
    -- ✅ Placement bot dans véhicule
    Config.DebugPrint('[BOT] ÉTAPE 11/12: Placement bot dans véhicule')
    
    TaskWarpPedIntoVehicle(botPed, botVehicle, -1)
    Wait(1000)
    
    attempts = 0
    maxAttempts = 15
    local botInVehicle = false
    
    while attempts < maxAttempts do
        attempts = attempts + 1
        
        local currentVeh = GetVehiclePedIsIn(botPed, false)
        botInVehicle = (currentVeh == botVehicle)
        
        if attempts % 3 == 0 then
            Config.DebugPrint(string.format('[BOT] Placement tentative %d/%d:', attempts, maxAttempts))
            Config.DebugPrint('[BOT]   Véhicule cible: ' .. botVehicle)
            Config.DebugPrint('[BOT]   Véhicule actuel: ' .. currentVeh)
            Config.DebugPrint('[BOT]   Dans véhicule: ' .. tostring(botInVehicle))
        end
        
        if botInVehicle then
            Config.SuccessPrint('[BOT] ✅ Bot placé dans véhicule après ' .. attempts .. ' tentatives')
            break
        end
        
        -- Réessayer
        TaskWarpPedIntoVehicle(botPed, botVehicle, -1)
        Wait(500)
        
        if attempts > 5 then
            SetPedIntoVehicle(botPed, botVehicle, -1)
            Wait(500)
        end
    end
    
    if not botInVehicle then
        Config.ErrorPrint('[BOT] ❌ ÉCHEC: Bot pas dans véhicule après ' .. attempts .. ' tentatives!')
        DeleteBot()
        return false
    end
    
    -- ✅ Configuration conduite
    Config.DebugPrint('[BOT] ÉTAPE 12/12: Configuration conduite')
    
    if Config.CoursePoursuit.BotRandomRoute then
        Config.DebugPrint('[BOT] Mode: Conduite aléatoire (Wander)')
        TaskVehicleDriveWander(botPed, botVehicle, Config.CoursePoursuit.BotSpeed, Config.CoursePoursuit.BotDrivingStyle)
    else
        local targetCoords = vector3(botCoords.x + 500.0, botCoords.y + 500.0, botCoords.z)
        Config.DebugPrint('[BOT] Mode: Conduite vers point')
        TaskVehicleDriveToCoordLongrange(botPed, botVehicle, targetCoords.x, targetCoords.y, targetCoords.z, Config.CoursePoursuit.BotSpeed, Config.CoursePoursuit.BotDrivingStyle, 10.0)
    end
    
    -- ✅ Libérer modèles
    SetModelAsNoLongerNeeded(modelHash)
    SetModelAsNoLongerNeeded(vehicleHash)
    
    Config.InfoPrint('╔═══════════════════════════════════════╗')
    Config.InfoPrint('║   SPAWN BOT RÉUSSI - 100% COMPLET    ║')
    Config.InfoPrint('╚═══════════════════════════════════════╝')
    Config.SuccessPrint('[BOT] 🤖 Bot PED ID: ' .. botPed)
    Config.SuccessPrint('[BOT] 🚙 Bot Vehicle ID: ' .. botVehicle)
    Config.SuccessPrint('[BOT] 🪣 Bucket: ' .. currentBucket)
    Config.SuccessPrint('[BOT] ✅ Bot configuré et en conduite!')
    
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
        
        -- ✅ CORRECTION: Stocker le bucket AVANT la synchronisation
        local expectedBucket = data.bucketId
        currentBucket = expectedBucket or 0
        
        if expectedBucket then
            Config.InfoPrint('Synchronisation routing bucket ' .. expectedBucket)
            Wait(3000) -- ✅ Attendre 3 secondes pour la synchronisation
            Config.SuccessPrint('Délai de synchronisation terminé')
        else
            Wait(3000)
        end
        
        Wait(1000)
        
        -- Récupération du véhicule créé par le serveur
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
        
        -- Personnalisation du véhicule
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
        
        Config.SuccessPrint('Véhicule personnalisé')
        
        -- Placement joueur
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
        
        Config.InfoPrint('Zone de guerre sera créée à votre première sortie')
        
        -- Décompte 3-2-1-GO
        StartCountdown()
        
        -- Calculer fin de jeu
        if Config.CoursePoursuit.GameDuration > 0 then
            gameEndTime = GetGameTimer() + (Config.CoursePoursuit.GameDuration * 1000)
        end
        
        -- ✅ NOUVEAU: Spawner bot IMMÉDIATEMENT (pas de délai)
        if data.spawnBot then
            Config.InfoPrint('Mode solo - spawn bot immédiatement')
            
            local botSpawned = SpawnBotAdversary()
            
            if not botSpawned then
                Config.ErrorPrint('Échec spawn bot - Mais le jeu continue')
            end
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
    vehicleExitThread = nil
    damageZoneThread = nil
    gameEndTime = nil
    gameStartTime = nil
    countdownActive = false
    canExitVehicle = false
    zoneCreatedOnExit = false
    currentBucket = 0
    warningMessageActive = false
    
    -- Masquer l'écran de mort
    SendNUIMessage({
        action = 'hideDeathScreen'
    })
    
    -- Supprimer la zone de guerre
    DeleteWarZone()
    
    local ped = PlayerPedId()
    
    -- ✅ NOUVEAU: Retirer l'arme donnée pendant la partie
    Config.DebugPrint('[STOP GAME] Retrait de l\'arme...')
    RemoveAllPedWeapons(ped, true)  -- Retirer TOUTES les armes
    Config.SuccessPrint('[STOP GAME] ✅ Armes retirées')
    
    -- Téléportation retour
    if Config.CoursePoursuit.ReturnToNormalCoords then
        DoScreenFadeOut(500)
        Wait(500)
        
        local returnCoords = Config.CoursePoursuit.ReturnToNormalCoords
        SetEntityCoords(ped, returnCoords.x, returnCoords.y, returnCoords.z, false, false, false, true)
        SetEntityHeading(ped, returnCoords.w)
        
        -- ✅ NOUVEAU: Ressusciter le joueur
        if IsEntityDead(ped) or GetEntityHealth(ped) <= 0 then
            Config.DebugPrint('[STOP GAME] Résurrection du joueur...')
            
            -- Ressusciter
            NetworkResurrectLocalPlayer(returnCoords.x, returnCoords.y, returnCoords.z, returnCoords.w, true, false)
            SetEntityHealth(ped, 200)  -- HP complet
            ClearPedTasksImmediately(ped)
            
            Config.SuccessPrint('[STOP GAME] ✅ Joueur ressuscité')
        end
        
        Wait(500)
        DoScreenFadeIn(500)
    end
    
    -- Supprimer le véhicule
    if DoesEntityExist(currentVehicle) then
        DeleteEntity(currentVehicle)
        currentVehicle = nil
        Config.DebugPrint('Véhicule joueur supprimé')
    end
    
    -- Supprimer le bot
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
-- ✅ THREAD DÉGÂTS ZONE DE GUERRE (AMÉLIORÉ)
-- ═══════════════════════════════════════════════════════════════

function StartDamageZoneThread()
    if damageZoneThread then
        Config.DebugPrint('[DAMAGE ZONE] Thread déjà actif, ignoré')
        return
    end
    
    Config.InfoPrint('[DAMAGE ZONE] 🔴 DÉMARRAGE THREAD DÉGÂTS')
    Config.DebugPrint('[DAMAGE ZONE] État initial:')
    Config.DebugPrint('[DAMAGE ZONE] - inGame: ' .. tostring(inGame))
    Config.DebugPrint('[DAMAGE ZONE] - warZoneActive: ' .. tostring(warZoneActive))
    Config.DebugPrint('[DAMAGE ZONE] - zoneCreatedOnExit: ' .. tostring(zoneCreatedOnExit))
    Config.DebugPrint('[DAMAGE ZONE] - warZonePosition: ' .. tostring(warZonePosition))
    
    damageZoneThread = CreateThread(function()
        local cycleCount = 0
        
        while inGame and warZoneActive do
            Wait(1000) -- Vérifier toutes les 1 seconde
            cycleCount = cycleCount + 1
            
            -- ✅ LOG: Cycle du thread
            if cycleCount % 5 == 0 then
                Config.DebugPrint('[DAMAGE ZONE] Thread actif - Cycle: ' .. cycleCount)
            end
            
            -- Attendre que la zone soit créée
            if not warZonePosition or not zoneCreatedOnExit then
                if cycleCount == 1 then
                    Config.DebugPrint('[DAMAGE ZONE] ⏳ Attente création zone...')
                end
                goto continue
            end
            
            if cycleCount == 1 then
                Config.SuccessPrint('[DAMAGE ZONE] ✅ Zone détectée, début surveillance')
            end
            
            local ped = PlayerPedId()
            
            -- ✅ Vérifier si le joueur est mort
            local isDead = IsEntityDead(ped)
            local health = GetEntityHealth(ped)
            
            if isDead or health <= 0 then
                Config.InfoPrint('[DAMAGE ZONE] 💀 JOUEUR MORT DÉTECTÉ')
                Config.DebugPrint('[DAMAGE ZONE] - Health: ' .. health)
                
                -- Afficher écran de mort
                SendNUIMessage({
                    action = 'showDeathScreen'
                })
                
                Wait(3000) -- Attendre 3 secondes
                
                -- Terminer la partie
                StopCoursePoursuiteGame()
                TriggerServerEvent('scharman:server:coursePoursuiteLeft', instanceId)
                ShowGameNotification('💀 Vous êtes mort ! Retour au PED...', 3000, 'error')
                
                break
            end
            
            local playerCoords = GetEntityCoords(ped)
            local distance = #(playerCoords - vector3(warZonePosition.x, warZonePosition.y, warZonePosition.z))
            
            Config.DebugPrint('[DAMAGE ZONE] Distance zone: ' .. string.format("%.1f", distance) .. 'm / ' .. warZoneRadius .. 'm')
            
            -- ✅ Si hors de la zone de guerre
            if distance > warZoneRadius then
                local currentHealth = GetEntityHealth(ped)
                local newHealth = currentHealth - 20
                
                Config.InfoPrint('[DAMAGE ZONE] ⚡ JOUEUR HORS ZONE!')
                Config.InfoPrint('[DAMAGE ZONE] - Distance: ' .. string.format("%.1f", distance) .. 'm')
                Config.InfoPrint('[DAMAGE ZONE] - HP: ' .. currentHealth .. ' → ' .. newHealth)
                
                -- ✅ Message d'avertissement persistant
                if not warningMessageActive then
                    warningMessageActive = true
                    Config.DebugPrint('[DAMAGE ZONE] Démarrage thread avertissement')
                    
                    CreateThread(function()
                        local warningCount = 0
                        while inGame and distance > warZoneRadius do
                            warningCount = warningCount + 1
                            ShowGameNotification('⚠️ HORS ZONE! Revenez ou vous allez mourir!', 1500, 'warning')
                            Config.DebugPrint('[DAMAGE ZONE] Avertissement #' .. warningCount)
                            Wait(2000)
                            
                            -- Recalculer la distance
                            local newCoords = GetEntityCoords(PlayerPedId())
                            distance = #(newCoords - vector3(warZonePosition.x, warZonePosition.y, warZonePosition.z))
                            Config.DebugPrint('[DAMAGE ZONE] Nouvelle distance: ' .. string.format("%.1f", distance) .. 'm')
                        end
                        
                        warningMessageActive = false
                        Config.SuccessPrint('[DAMAGE ZONE] ✅ Fin avertissements')
                        ShowGameNotification('✅ Retour dans la zone!', 2000, 'success')
                    end)
                end
                
                -- Infliger dégâts
                SetEntityHealth(ped, math.max(0, newHealth))
                Config.SuccessPrint('[DAMAGE ZONE] Dégâts infligés: -20 HP')
                
                -- ✅ DÉSACTIVÉ: Ragdoll fait tomber le joueur
                -- SetPedToRagdoll(ped, 500, 500, 0, 0, 0, 0)
                
                -- Notification de dégâts
                ShowGameNotification('⚡ DÉGÂTS ZONE: -20 HP', 1500, 'error')
                
                -- ✅ Vérifier si mort après dégâts
                if newHealth <= 0 then
                    Config.InfoPrint('[DAMAGE ZONE] 💀 JOUEUR TUÉ PAR LA ZONE')
                    -- Le thread détectera la mort au prochain cycle
                end
            else
                -- Dans la zone - réinitialiser le flag d'avertissement
                if warningMessageActive then
                    Config.DebugPrint('[DAMAGE ZONE] Joueur revenu dans zone, stop avertissements')
                end
                warningMessageActive = false
            end
            
            ::continue::
        end
        
        damageZoneThread = nil
        Config.InfoPrint('[DAMAGE ZONE] 🔴 ARRÊT THREAD DÉGÂTS')
        Config.DebugPrint('[DAMAGE ZONE] - Raison: inGame=' .. tostring(inGame) .. ', warZoneActive=' .. tostring(warZoneActive))
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

local function StartVehicleExitDetectionThread()
    if vehicleExitThread then return end
    
    vehicleExitThread = CreateThread(function()
        Config.DebugPrint('Thread détection sortie véhicule démarré')
        
        while inGame and not zoneCreatedOnExit do
            Wait(500)
            
            local ped = PlayerPedId()
            
            -- Si le joueur peut sortir ET n'est PAS dans un véhicule
            if canExitVehicle and not IsPedInAnyVehicle(ped, false) then
                -- Créer la zone de guerre à la position actuelle
                local coords = GetEntityCoords(ped)
                CreateWarZone(coords)
                ShowGameNotification('🔴 ZONE DE GUERRE créée à votre position !', 5000, 'warning')
                
                -- Donner l'arme CAL50
                local weaponHash = GetHashKey('WEAPON_PISTOL50')
                GiveWeaponToPed(ped, weaponHash, 250, false, true)
                SetCurrentPedWeapon(ped, weaponHash, true)
                Config.SuccessPrint('Arme donnée: Pistolet Cal .50')
                ShowGameNotification('🔫 Pistolet Cal .50 équipé !', 3000, 'success')
                
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
    Config.DebugPrint('[GAME THREADS] Démarrage threads de jeu')
    StartBlockExitThread()
    StartZoneCheckThread()
    StartGameTimerThread()
    StartVehicleExitDetectionThread()
    -- ✅ CORRECTION: Ne PAS démarrer damageZoneThread ici
    -- Il sera démarré dans CreateWarZone() quand la zone est créée
    Config.DebugPrint('[GAME THREADS] Threads lancés (sauf dégâts zone)')
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
        print('Bucket: ' .. currentBucket)
        print('Zone de guerre: ' .. (warZoneActive and 'ACTIVE' or 'INACTIVE'))
        print('Zone créée: ' .. (zoneCreatedOnExit and 'OUI' or 'NON'))
        print('Peut sortir véhicule: ' .. (canExitVehicle and 'OUI' or 'NON'))
        print('Bot PED: ' .. (botPed or 'Aucun'))
        print('Bot Vehicle: ' .. (botVehicle or 'Aucun'))
        print('═══════════════════════════════════════════════════════════════')
    end, false)
end

Config.DebugPrint('client/course_poursuite.lua V2 CORRIGÉ chargé')
