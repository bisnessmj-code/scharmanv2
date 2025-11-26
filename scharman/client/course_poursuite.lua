-- ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
-- ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
-- ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
-- ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
-- ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
-- CLIENT - MODE COURSE POURSUITE (CORRIGÉ)
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

-- ✅ NOUVELLES VARIABLES - ZONE DE GUERRE
local canExitVehicle = false           -- Autorisé à sortir après 30s
local warZoneActive = false            -- Zone de guerre créée
local warZonePosition = nil            -- Position de la zone de guerre
local warZoneBlip = nil                -- Blip sur la map
local warZoneThread = nil              -- Thread de rendu de la zone
local gameStartTime = nil              -- Temps de début du jeu

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

-- Charger un modèle avec timeout
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

-- Placer le joueur dans un véhicule de manière robuste
local function ForcePlayerIntoVehicle(ped, vehicle, seat)
    Config.DebugPrint('Tentative de placement du joueur dans le véhicule...')
    
    -- Vérifications de base
    if not DoesEntityExist(vehicle) then
        Config.ErrorPrint('Le véhicule n\'existe pas!')
        return false
    end
    
    if not DoesEntityExist(ped) then
        Config.ErrorPrint('Le PED n\'existe pas!')
        return false
    end
    
    -- S'assurer que le véhicule est au sol
    SetVehicleOnGroundProperly(vehicle)
    Wait(100)
    
    Config.DebugPrint('État avant placement:')
    Config.DebugPrint('- Véhicule existe: ' .. tostring(DoesEntityExist(vehicle)))
    Config.DebugPrint('- PED existe: ' .. tostring(DoesEntityExist(ped)))
    Config.DebugPrint('- Siège: ' .. tostring(seat))
    
    -- Méthode 1: TaskWarpPedIntoVehicle
    TaskWarpPedIntoVehicle(ped, vehicle, seat)
    Wait(500)
    
    -- Vérifier si le joueur est dans le véhicule
    local attempts = 0
    local maxAttempts = 10
    
    while GetVehiclePedIsIn(ped, false) ~= vehicle and attempts < maxAttempts do
        attempts = attempts + 1
        Config.DebugPrint('Tentative ' .. attempts .. '/' .. maxAttempts .. ' de placement...')
        
        -- Réessayer avec TaskWarpPedIntoVehicle
        TaskWarpPedIntoVehicle(ped, vehicle, seat)
        Wait(300)
        
        -- Si ça ne marche toujours pas, essayer SetPedIntoVehicle
        if GetVehiclePedIsIn(ped, false) ~= vehicle then
            Config.DebugPrint('TaskWarp échoué, essai avec SetPedIntoVehicle...')
            SetPedIntoVehicle(ped, vehicle, seat)
            Wait(300)
        end
    end
    
    -- Vérification finale
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
-- FONCTIONS BOT ADVERSAIRE
-- ═══════════════════════════════════════════════════════════════

-- Supprimer le bot
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

-- Spawner un bot adversaire
local function SpawnBotAdversary()
    if not Config.CoursePoursuit.SpawnBotInSolo then
        Config.DebugPrint('Spawn bot désactivé dans la config')
        return false
    end
    
    Config.InfoPrint('═══ DÉBUT SPAWN BOT ═══')
    
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local playerHeading = GetEntityHeading(ped)
    
    Config.DebugPrint('Position joueur: ' .. tostring(playerCoords))
    Config.DebugPrint('Heading joueur: ' .. tostring(playerHeading))
    
    -- Calculer la position du bot (à côté du joueur)
    local offset = Config.CoursePoursuit.BotSpawnOffset
    local forwardX = math.cos(math.rad(playerHeading))
    local forwardY = math.sin(math.rad(playerHeading))
    
    local botCoords = vector3(
        playerCoords.x + (forwardX * offset.x) + offset.y,
        playerCoords.y + (forwardY * offset.x),
        playerCoords.z + offset.z
    )
    
    Config.DebugPrint('Position bot calculée: ' .. tostring(botCoords))
    
    -- Charger le modèle du bot
    if not LoadModel(Config.CoursePoursuit.BotModel) then
        Config.ErrorPrint('Échec chargement modèle bot')
        return false
    end
    
    -- Créer le bot
    Config.DebugPrint('Création du PED bot...')
    botPed = CreatePed(4, GetHashKey(Config.CoursePoursuit.BotModel), botCoords.x, botCoords.y, botCoords.z, playerHeading, true, true)  -- ✅ CORRECTION: true, true pour forcer création réseau
    
    -- Attendre synchronisation
    Wait(300)
    
    if not DoesEntityExist(botPed) then
        Config.ErrorPrint('Échec création bot')
        SetModelAsNoLongerNeeded(GetHashKey(Config.CoursePoursuit.BotModel))
        return false
    end
    
    Config.SuccessPrint('Bot créé: ' .. botPed)
    Config.DebugPrint('Bot existe: ' .. tostring(DoesEntityExist(botPed)))
    
    -- Rendre le bot invincible
    SetEntityInvincible(botPed, true)
    SetBlockingOfNonTemporaryEvents(botPed, true)
    
    -- Charger le modèle du véhicule bot
    if not LoadModel(Config.CoursePoursuit.BotVehicle) then
        Config.ErrorPrint('Échec chargement véhicule bot')
        DeleteEntity(botPed)
        botPed = nil
        return false
    end
    
    -- Créer le véhicule du bot
    Config.DebugPrint('Création du véhicule bot...')
    botVehicle = CreateVehicle(
        GetHashKey(Config.CoursePoursuit.BotVehicle),
        botCoords.x,
        botCoords.y,
        botCoords.z,
        playerHeading,
        true,
        true  -- ✅ CORRECTION: true pour forcer la création réseau
    )
    
    -- Attendre synchronisation
    Wait(500)
    
    if not DoesEntityExist(botVehicle) then
        Config.ErrorPrint('Échec création véhicule bot')
        DeleteEntity(botPed)
        botPed = nil
        SetModelAsNoLongerNeeded(GetHashKey(Config.CoursePoursuit.BotVehicle))
        return false
    end
    
    Config.SuccessPrint('Véhicule bot créé: ' .. botVehicle)
    Config.DebugPrint('Véhicule bot existe: ' .. tostring(DoesEntityExist(botVehicle)))
    
    -- Personnaliser le véhicule bot
    local botColor = Config.CoursePoursuit.BotVehicleColor
    SetVehicleCustomPrimaryColour(botVehicle, botColor.primary.r, botColor.primary.g, botColor.primary.b)
    SetVehicleCustomSecondaryColour(botVehicle, botColor.secondary.r, botColor.secondary.g, botColor.secondary.b)
    SetVehicleNumberPlateText(botVehicle, 'BOT~AI')
    
    -- Vérifier après personnalisation
    if not DoesEntityExist(botVehicle) then
        Config.ErrorPrint('Véhicule bot disparu après personnalisation')
        DeleteEntity(botPed)
        botPed = nil
        return false
    end
    
    -- Rendre le véhicule plus résistant
    SetVehicleEngineHealth(botVehicle, 1000.0)
    SetVehicleBodyHealth(botVehicle, 1000.0)
    SetVehicleOnGroundProperly(botVehicle)
    
    Config.DebugPrint('Véhicule bot personnalisé')
    
    -- Attendre que le véhicule soit bien chargé
    Wait(1000)  -- ✅ CORRECTION: Wait augmenté de 500 à 1000
    
    -- Vérification finale
    if not DoesEntityExist(botVehicle) then
        Config.ErrorPrint('Véhicule bot disparu avant placement')
        DeleteEntity(botPed)
        botPed = nil
        return false
    end
    
    -- Mettre le bot dans le véhicule (siège conducteur = -1)
    Config.DebugPrint('Placement du bot dans le véhicule...')
    
    TaskWarpPedIntoVehicle(botPed, botVehicle, -1)
    Wait(1000)
    
    -- Vérifier que le bot est dans le véhicule
    local attempts = 0
    local maxAttempts = 5
    
    while GetVehiclePedIsIn(botPed, false) ~= botVehicle and attempts < maxAttempts do
        attempts = attempts + 1
        Config.DebugPrint('Tentative ' .. attempts .. ' de placement du bot...')
        TaskWarpPedIntoVehicle(botPed, botVehicle, -1)
        Wait(500)
        
        if GetVehiclePedIsIn(botPed, false) ~= botVehicle then
            SetPedIntoVehicle(botPed, botVehicle, -1)
            Wait(500)
        end
    end
    
    local botInVehicle = GetVehiclePedIsIn(botPed, false) == botVehicle
    
    Config.DebugPrint('Bot dans véhicule: ' .. tostring(botInVehicle))
    
    if not botInVehicle then
        Config.ErrorPrint('ÉCHEC: Bot pas dans le véhicule!')
        DeleteBot()
        return false
    end
    
    -- Faire conduire le bot
    Config.DebugPrint('Configuration de la conduite du bot...')
    
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
    
    Config.InfoPrint('═══ FIN SPAWN BOT - SUCCÈS ═══')
    Config.SuccessPrint('Bot adversaire spawné et en conduite!')
    ShowGameNotification('🤖 Un adversaire bot est apparu !', 4000, 'success')
    
    return true
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
    
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    Config.InfoPrint('DÉMARRAGE DE LA COURSE POURSUITE')
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    
    -- Protection contre écran noir avec pcall
    local success, err = pcall(function()
        local ped = PlayerPedId()
        instanceId = data.instanceId
        
        Config.DebugPrint('Instance ID: ' .. tostring(instanceId))
        Config.DebugPrint('PED ID: ' .. tostring(ped))
        
        -- Récupérer les coordonnées et le modèle
        local spawnCoords = data.spawnCoords or Config.CoursePoursuit.SpawnCoords
        local vehicleModel = data.vehicleModel or Config.CoursePoursuit.VehicleModel
        
        Config.DebugPrint('Spawn coords: ' .. tostring(spawnCoords))
        Config.DebugPrint('Vehicle model: ' .. vehicleModel)
        
        -- Notification de téléportation
        ShowGameNotification(Config.CoursePoursuit.Notifications.teleporting, 2000, 'info')
        
        -- Fade out
        Config.DebugPrint('Fade out...')
        DoScreenFadeOut(800)
        while not IsScreenFadedOut() do
            Wait(10)
        end
        Config.DebugPrint('Écran noir')
        
        -- Téléporter le joueur
        Config.DebugPrint('Téléportation du joueur...')
        SetEntityCoords(ped, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, true)
        SetEntityHeading(ped, spawnCoords.w)
        Config.DebugPrint('Joueur téléporté')
        
        -- ✅ CORRECTION V4: Attendre synchronisation du routing bucket
        -- Note: GetPlayerRoutingBucket() n'existe pas côté client
        -- On attend simplement un délai suffisant pour la synchronisation réseau
        local expectedBucket = data.bucketId
        if expectedBucket then
            Config.InfoPrint('Synchronisation routing bucket ' .. expectedBucket .. ' en cours...')
            Config.DebugPrint('Attente de 3 secondes pour synchronisation réseau...')
            
            -- Attendre 3 secondes pour laisser le temps au serveur de synchroniser le bucket
            Wait(3000)
            
            Config.SuccessPrint('Délai de synchronisation terminé')
        else
            -- Pas de bucket fourni, attendre quand même
            Config.DebugPrint('Pas de bucket ID fourni, attente 3 secondes...')
            Wait(3000)
        end
        
        -- Attendre stabilisation supplémentaire
        Wait(1000)
        
        -- ✅ V5: Récupérer le véhicule créé par le serveur via Network ID
        local vehicleNetId = data.vehicleNetId
        
        if vehicleNetId then
            Config.InfoPrint('═══ RÉCUPÉRATION VÉHICULE SERVEUR (V5) ═══')
            Config.DebugPrint('Vehicle Network ID reçu: ' .. vehicleNetId)
            
            -- Attendre que le véhicule réseau soit synchronisé
            local maxAttempts = 100  -- 10 secondes max
            local attempt = 0
            
            repeat
                currentVehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
                
                if currentVehicle and DoesEntityExist(currentVehicle) then
                    Config.SuccessPrint('Véhicule récupéré avec succès: ' .. currentVehicle)
                    break
                end
                
                attempt = attempt + 1
                Wait(100)
                
                if attempt % 10 == 0 then
                    Config.DebugPrint('Attente véhicule réseau... Tentative ' .. attempt .. '/100')
                end
            until attempt >= maxAttempts
            
            if not currentVehicle or not DoesEntityExist(currentVehicle) then
                error('Échec récupération véhicule réseau après ' .. (maxAttempts * 100) .. 'ms - NetID: ' .. vehicleNetId)
            end
            
            Config.DebugPrint('Véhicule existe: ' .. tostring(DoesEntityExist(currentVehicle)))
            Config.DebugPrint('Véhicule handle: ' .. currentVehicle)
            
            -- S'assurer que le véhicule est au sol
            SetVehicleOnGroundProperly(currentVehicle)
            Wait(500)
            
        else
            -- ❌ FALLBACK: Créer le véhicule côté client (ancien système)
            Config.ErrorPrint('ATTENTION: Pas de Network ID reçu, utilisation ancien système')
            
            -- Charger le modèle du véhicule
            Config.DebugPrint('Chargement du modèle de véhicule...')
            if not LoadModel(vehicleModel) then
                error('Échec du chargement du modèle de véhicule: ' .. vehicleModel)
            end
            
            -- Créer le véhicule
            Config.DebugPrint('Création du véhicule joueur...')
            currentVehicle = CreateVehicle(
                GetHashKey(vehicleModel),
                spawnCoords.x,
                spawnCoords.y,
                spawnCoords.z,
                spawnCoords.w,
                true,
                true
            )
            
            Config.DebugPrint('Véhicule handle: ' .. tostring(currentVehicle))
            
            -- Attendre que le véhicule soit synchronisé
            Config.DebugPrint('Attente synchronisation véhicule...')
            Wait(1500)
            
            -- Vérifier existence
            Config.DebugPrint('Vérification existence véhicule...')
            if not DoesEntityExist(currentVehicle) then
                error('Échec de la création du véhicule - Handle: ' .. tostring(currentVehicle) .. ' - DoesEntityExist: false')
            end
            
            Config.SuccessPrint('Véhicule créé: ' .. currentVehicle)
            Config.DebugPrint('Véhicule existe après création: ' .. tostring(DoesEntityExist(currentVehicle)))
            
            -- S'assurer que le véhicule est au sol
            SetVehicleOnGroundProperly(currentVehicle)
            Wait(500)
            
            -- Vérifier que le véhicule existe toujours
            if not DoesEntityExist(currentVehicle) then
                error('Le véhicule a disparu après SetVehicleOnGroundProperly')
            end
            Config.DebugPrint('Véhicule existe après ground properly: true')
        end
        
        -- ✅ V5: Personnaliser le véhicule SEULEMENT si créé côté client (fallback)
        if not vehicleNetId then
            -- Véhicule créé côté client, on le personnalise
            Config.DebugPrint('Personnalisation du véhicule (client-side)...')
            
            -- Vérifier l'existence avant chaque opération
            if not DoesEntityExist(currentVehicle) then
                error('Le véhicule a disparu avant la personnalisation')
            end
            
            local primaryColor = Config.CoursePoursuit.VehicleCustomization.primaryColor
            local secondaryColor = Config.CoursePoursuit.VehicleCustomization.secondaryColor
            SetVehicleCustomPrimaryColour(currentVehicle, primaryColor.r, primaryColor.g, primaryColor.b)
            SetVehicleCustomSecondaryColour(currentVehicle, secondaryColor.r, secondaryColor.g, secondaryColor.b)
            
            -- Vérifier après couleurs
            if not DoesEntityExist(currentVehicle) then
                error('Le véhicule a disparu après les couleurs')
            end
            Config.DebugPrint('Couleurs appliquées')
            
            -- Appliquer les mods
            local mods = Config.CoursePoursuit.VehicleCustomization.mods
            SetVehicleMod(currentVehicle, 11, mods.engine, false)
            SetVehicleMod(currentVehicle, 12, mods.brakes, false)
            SetVehicleMod(currentVehicle, 13, mods.transmission, false)
            SetVehicleMod(currentVehicle, 15, mods.suspension, false)
            ToggleVehicleMod(currentVehicle, 18, mods.turbo)
            
            -- Vérifier après mods
            if not DoesEntityExist(currentVehicle) then
                error('Le véhicule a disparu après les mods')
            end
            Config.DebugPrint('Mods appliqués')
            
            -- Plaque d'immatriculation
            SetVehicleNumberPlateText(currentVehicle, 'COURSE')
            
            -- Remplir essence (avec protection)
            local success, err = pcall(function()
                SetVehicleFuelLevel(currentVehicle, 100.0)
            end)
            if not success then
                Config.DebugPrint('SetVehicleFuelLevel échoué (normal si pas de script fuel): ' .. tostring(err))
            end
            
            -- Vérifier après essence
            if not DoesEntityExist(currentVehicle) then
                error('Le véhicule a disparu après SetVehicleFuelLevel')
            end
            Config.DebugPrint('Essence configurée')
            
            -- Santé du véhicule
            SetVehicleEngineHealth(currentVehicle, 1000.0)
            SetVehicleBodyHealth(currentVehicle, 1000.0)
            
            -- Vérifier après santé
            if not DoesEntityExist(currentVehicle) then
                error('Le véhicule a disparu après santé')
            end
            Config.DebugPrint('Santé configurée')
            
            -- Verrouiller les portes
            SetVehicleDoorsLocked(currentVehicle, 2)
            SetVehicleDoorsLockedForAllPlayers(currentVehicle, true)
            
            -- Vérification finale
            if not DoesEntityExist(currentVehicle) then
                error('Le véhicule a disparu après verrouillage')
            end
            
            Config.DebugPrint('Véhicule personnalisé - Existe: ' .. tostring(DoesEntityExist(currentVehicle)))
            
            -- Attendre que le véhicule soit stable
            Wait(1000)
            
            -- Vérification finale avant placement
            if not DoesEntityExist(currentVehicle) then
                error('Le véhicule a disparu avant le placement du joueur')
            end
            Config.DebugPrint('Véhicule stable et prêt pour placement')
        else
            -- Véhicule créé côté serveur, on le personnalise maintenant côté client
            Config.InfoPrint('Personnalisation du véhicule récupéré du serveur...')
            
            -- Vérifier existence
            if not DoesEntityExist(currentVehicle) then
                error('Le véhicule n\'existe pas avant personnalisation')
            end
            
            -- Couleurs
            local primaryColor = Config.CoursePoursuit.VehicleCustomization.primaryColor
            local secondaryColor = Config.CoursePoursuit.VehicleCustomization.secondaryColor
            SetVehicleCustomPrimaryColour(currentVehicle, primaryColor.r, primaryColor.g, primaryColor.b)
            SetVehicleCustomSecondaryColour(currentVehicle, secondaryColor.r, secondaryColor.g, secondaryColor.b)
            Config.DebugPrint('Couleurs appliquées')
            
            -- Mods
            local mods = Config.CoursePoursuit.VehicleCustomization.mods
            SetVehicleMod(currentVehicle, 11, mods.engine, false)
            SetVehicleMod(currentVehicle, 12, mods.brakes, false)
            SetVehicleMod(currentVehicle, 13, mods.transmission, false)
            SetVehicleMod(currentVehicle, 15, mods.suspension, false)
            ToggleVehicleMod(currentVehicle, 18, mods.turbo)
            Config.DebugPrint('Mods appliqués')
            
            -- Plaque
            SetVehicleNumberPlateText(currentVehicle, 'COURSE')
            
            -- Essence (avec protection)
            local success, err = pcall(function()
                SetVehicleFuelLevel(currentVehicle, 100.0)
            end)
            if not success then
                Config.DebugPrint('SetVehicleFuelLevel échoué: ' .. tostring(err))
            end
            
            -- Santé
            SetVehicleEngineHealth(currentVehicle, 1000.0)
            SetVehicleBodyHealth(currentVehicle, 1000.0)
            
            -- Verrouillage
            SetVehicleDoorsLocked(currentVehicle, 2)
            SetVehicleDoorsLockedForAllPlayers(currentVehicle, true)
            
            Config.SuccessPrint('Véhicule personnalisé côté client')
            
            -- Vérifier que le véhicule existe toujours
            if not DoesEntityExist(currentVehicle) then
                error('Le véhicule a disparu après personnalisation')
            end
        end
        
        Config.DebugPrint('Véhicule prêt pour placement')
        
        -- PLACEMENT DU JOUEUR DANS LE VÉHICULE (robuste)
        Config.InfoPrint('═══ PLACEMENT JOUEUR DANS VÉHICULE ═══')
        local placementSuccess = ForcePlayerIntoVehicle(ped, currentVehicle, -1)
        
        if not placementSuccess then
            error('ÉCHEC CRITIQUE: Impossible de placer le joueur dans le véhicule')
        end
        
        -- Libérer le modèle
        SetModelAsNoLongerNeeded(GetHashKey(vehicleModel))
        
        -- Fade in
        Config.DebugPrint('Fade in...')
        DoScreenFadeIn(500)
        while not IsScreenFadedIn() do
            Wait(10)
        end
        Config.DebugPrint('Écran visible')
        
        -- Marquer comme en jeu
        inGame = true
        Config.SuccessPrint('État: EN JEU')
        
        -- Notification de démarrage
        ShowGameNotification(Config.CoursePoursuit.Notifications.starting, 3000, 'info')
        Wait(3000)
        ShowGameNotification(Config.CoursePoursuit.Notifications.started, 3000, 'success')
        
        -- ✅ Initialiser le temps de début
        gameStartTime = GetGameTimer()
        
        -- Calculer l'heure de fin si durée définie
        if Config.CoursePoursuit.GameDuration > 0 then
            gameEndTime = GetGameTimer() + (Config.CoursePoursuit.GameDuration * 1000)
            Config.DebugPrint('Durée de jeu: ' .. Config.CoursePoursuit.GameDuration .. 's')
        end
        
        -- Spawner un bot si mode solo activé
        if data.spawnBot then
            Config.InfoPrint('Mode solo détecté, spawn du bot dans 2 secondes...')
            Wait(2000)
            
            local botSpawned = SpawnBotAdversary()
            
            if not botSpawned then
                Config.ErrorPrint('Échec du spawn du bot, mais la partie continue')
            end
        end
        
        -- Démarrer les threads de gestion
        StartGameThreads()
        
        Config.InfoPrint('═══════════════════════════════════════════════════════════════')
        Config.SuccessPrint('COURSE POURSUITE DÉMARRÉE AVEC SUCCÈS!')
        Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    end)
    
    -- Si erreur, restaurer l'écran et nettoyer
    if not success then
        Config.ErrorPrint('═══════════════════════════════════════════════════════════════')
        Config.ErrorPrint('ERREUR CRITIQUE lors du démarrage:')
        Config.ErrorPrint(tostring(err))
        Config.ErrorPrint('═══════════════════════════════════════════════════════════════')
        
        -- TOUJOURS faire le fade in pour éviter écran noir
        if IsScreenFadedOut() then
            DoScreenFadeIn(500)
        end
        
        -- Nettoyer
        if DoesEntityExist(currentVehicle) then
            DeleteEntity(currentVehicle)
            currentVehicle = nil
        end
        
        DeleteBot()
        
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
    
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    Config.InfoPrint('ARRÊT DU MODE COURSE POURSUITE')
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    
    -- Marquer comme pas en jeu
    inGame = false
    
    -- Arrêter les threads
    blockExitThread = nil
    zoneCheckThread = nil
    gameEndTime = nil
    gameStartTime = nil
    warZoneThread = nil
    
    -- ✅ Nettoyer la zone de guerre
    if warZoneBlip then
        RemoveBlip(warZoneBlip)
        warZoneBlip = nil
    end
    canExitVehicle = false
    warZoneActive = false
    warZonePosition = nil
    Config.DebugPrint('Zone de guerre nettoyée')
    
    local ped = PlayerPedId()
    
    -- Téléporter le joueur à la position de retour
    if Config.CoursePoursuit.ReturnToNormalCoords then
        Config.DebugPrint('Téléportation de retour...')
        DoScreenFadeOut(500)
        Wait(500)
        
        local returnCoords = Config.CoursePoursuit.ReturnToNormalCoords
        SetEntityCoords(ped, returnCoords.x, returnCoords.y, returnCoords.z, false, false, false, true)
        SetEntityHeading(ped, returnCoords.w)
        
        Wait(500)
        DoScreenFadeIn(500)
        Config.DebugPrint('Joueur téléporté au PED')
    end
    
    -- Supprimer le véhicule
    if DoesEntityExist(currentVehicle) then
        DeleteEntity(currentVehicle)
        currentVehicle = nil
        Config.DebugPrint('Véhicule joueur supprimé')
    end
    
    -- Supprimer le bot
    DeleteBot()
    
    -- Réinitialiser instanceId
    instanceId = nil
    
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    Config.SuccessPrint('NETTOYAGE TERMINÉ')
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
end

-- ═══════════════════════════════════════════════════════════════
-- THREADS DE GESTION
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- ZONE DE GUERRE
-- ═══════════════════════════════════════════════════════════════

-- Créer le blip de la zone de guerre sur la map
local function CreateWarZoneBlip()
    if warZoneBlip then
        RemoveBlip(warZoneBlip)
    end
    
    warZoneBlip = AddBlipForRadius(warZonePosition.x, warZonePosition.y, warZonePosition.z, 50.0)
    SetBlipHighDetail(warZoneBlip, true)
    SetBlipColour(warZoneBlip, 1) -- Rouge
    SetBlipAlpha(warZoneBlip, 128) -- Semi-transparent
    
    -- Ajouter un blip point au centre
    local centerBlip = AddBlipForCoord(warZonePosition.x, warZonePosition.y, warZonePosition.z)
    SetBlipSprite(centerBlip, 84) -- Icône crâne
    SetBlipDisplay(centerBlip, 4)
    SetBlipScale(centerBlip, 1.2)
    SetBlipColour(centerBlip, 1) -- Rouge
    SetBlipAsShortRange(centerBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("🔴 ZONE DE GUERRE")
    EndTextCommandSetBlipName(centerBlip)
    
    Config.SuccessPrint('Blip zone de guerre créé')
end

-- Thread de rendu de la zone de guerre (colonne de lumière)
local function StartWarZoneThread()
    if warZoneThread then return end
    
    Config.InfoPrint('Thread de rendu zone de guerre démarré')
    
    warZoneThread = CreateThread(function()
        while inGame and warZoneActive and warZonePosition do
            Wait(0)
            
            local pos = warZonePosition
            
            -- Dessiner la colonne de lumière rouge (cylinder marker)
            -- Type 28 = Cylindre vertical
            DrawMarker(
                28,                          -- Type : Cylindre vertical inversé (colonne)
                pos.x, pos.y, pos.z,        -- Position
                0.0, 0.0, 0.0,              -- Direction
                0.0, 0.0, 0.0,              -- Rotation
                50.0, 50.0, 150.0,          -- Scale (rayon 50m, hauteur 150m)
                255, 0, 0, 100,             -- Couleur RGBA (rouge semi-transparent)
                false,                       -- Bob up and down
                false,                       -- Face camera
                2,                           -- Rotation
                false,                       -- Rotate
                nil, nil,                   -- Texture
                false                        -- Project
            )
            
            -- Dessiner un cercle au sol (rayon 50m)
            DrawMarker(
                1,                           -- Type : Cylindre au sol
                pos.x, pos.y, pos.z - 1.0,  -- Position (légèrement sous le sol)
                0.0, 0.0, 0.0,              -- Direction
                0.0, 0.0, 0.0,              -- Rotation
                100.0, 100.0, 1.0,          -- Scale (diamètre 100m = rayon 50m)
                255, 0, 0, 150,             -- Couleur RGBA (rouge)
                false,                       -- Bob
                false,                       -- Face camera
                2,                           -- Rotation
                false,                       -- Rotate
                nil, nil,                   -- Texture
                false                        -- Project
            )
        end
        
        warZoneThread = nil
        Config.DebugPrint('Thread de rendu zone de guerre arrêté')
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- THREADS DE GESTION
-- ═══════════════════════════════════════════════════════════════

-- Thread de blocage de sortie du véhicule
local function StartBlockExitThread()
    if blockExitThread then return end
    
    Config.DebugPrint('Thread de blocage de sortie démarré')
    
    -- Démarrer le timer de 30 secondes
    CreateThread(function()
        Wait(30000) -- 30 secondes
        canExitVehicle = true
        Config.SuccessPrint('✅ Vous pouvez maintenant sortir du véhicule !')
        ShowGameNotification('✅ Vous pouvez maintenant sortir du véhicule !', 5000, 'success')
    end)
    
    blockExitThread = CreateThread(function()
        local wasInVehicle = true
        
        while inGame and Config.CoursePoursuit.BlockExitVehicle do
            Wait(0)
            
            local ped = PlayerPedId()
            local isInVehicle = IsPedInVehicle(ped, currentVehicle, false)
            
            -- Si pas encore autorisé à sortir
            if not canExitVehicle then
                -- Bloquer la touche F (sortir du véhicule)
                DisableControlAction(0, 75, true) -- INPUT_VEH_EXIT
                
                -- Si le joueur essaye de sortir
                if IsDisabledControlJustPressed(0, 75) then
                    local timeElapsed = (GetGameTimer() - gameStartTime) / 1000
                    local timeLeft = math.max(0, 30 - timeElapsed)
                    ShowGameNotification(string.format('⏰ Attendez encore %d secondes avant de pouvoir sortir !', math.ceil(timeLeft)), 3000, 'warning')
                    Config.DebugPrint('Tentative de sortie bloquée (trop tôt)')
                end
                
                -- Si le joueur est sorti (par un bug), le remettre dans le véhicule
                if DoesEntityExist(currentVehicle) and not isInVehicle then
                    Config.DebugPrint('Joueur sorti du véhicule avant 30s, replacement forcé!')
                    ForcePlayerIntoVehicle(ped, currentVehicle, -1)
                    ShowGameNotification('🚗 Retour forcé dans le véhicule ! Attendez 30 secondes.', 3000, 'warning')
                end
            else
                -- Après 30s, autoriser la sortie mais détecter quand le joueur sort
                if wasInVehicle and not isInVehicle and not warZoneActive then
                    -- Le joueur vient de sortir du véhicule !
                    local playerCoords = GetEntityCoords(ped)
                    warZonePosition = playerCoords
                    warZoneActive = true
                    
                    Config.SuccessPrint('🔴 ZONE DE GUERRE CRÉÉE À VOTRE POSITION !')
                    ShowGameNotification('🔴 ZONE DE GUERRE créée à votre position !', 5000, 'error')
                    
                    -- Créer le blip sur la map
                    CreateWarZoneBlip()
                    
                    -- Démarrer le thread de rendu de la zone
                    StartWarZoneThread()
                end
            end
            
            wasInVehicle = isInVehicle
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
            
            -- Vérifier que gameEndTime existe toujours (peut être nil après StopCoursePoursuiteGame)
            if not gameEndTime then
                break
            end
            
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
    Config.DebugPrint('Démarrage des threads de gestion...')
    StartBlockExitThread()
    StartZoneCheckThread()
    StartGameTimerThread()
    Config.DebugPrint('Threads démarrés')
end

-- ═══════════════════════════════════════════════════════════════
-- ÉVÉNEMENTS
-- ═══════════════════════════════════════════════════════════════

-- Démarrer le jeu
RegisterNetEvent('scharman:client:startCoursePoursuit', function(data)
    Config.DebugPrint('Événement startCoursePoursuit reçu')
    StartCoursePoursuiteGame(data)
end)

-- Arrêter le jeu
RegisterNetEvent('scharman:client:stopCoursePoursuit', function()
    Config.DebugPrint('Événement stopCoursePoursuit reçu')
    StopCoursePoursuiteGame()
end)

-- Notification
RegisterNetEvent('scharman:client:courseNotification', function(message, duration, notifType)
    ShowGameNotification(message, duration or 3000, notifType or 'info')
end)

-- ═══════════════════════════════════════════════════════════════
-- COMMANDES DEBUG
-- ═══════════════════════════════════════════════════════════════

-- Commande pour quitter la partie en cours
RegisterCommand('quit_course', function()
    if inGame then
        Config.InfoPrint('Commande /quit_course utilisée')
        StopCoursePoursuiteGame()
        TriggerServerEvent('scharman:server:coursePoursuiteLeft', instanceId)
        ShowGameNotification('✅ Vous avez quitté la partie', 3000, 'success')
    else
        ShowGameNotification('❌ Vous n\'êtes pas en partie', 3000, 'error')
    end
end, false)

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
        print('Véhicule existe: ' .. tostring(DoesEntityExist(currentVehicle)))
        print('Bot PED: ' .. (botPed or 'Aucun'))
        print('Bot Véhicule: ' .. (botVehicle or 'Aucun'))
        
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        print('Joueur dans véhicule: ' .. tostring(veh))
        print('Joueur dans currentVehicle: ' .. tostring(veh == currentVehicle))
        
        if gameEndTime then
            local timeLeft = gameEndTime - GetGameTimer()
            print('Temps restant: ' .. math.floor(timeLeft / 1000) .. 's')
        end
        print('═══════════════════════════════════════════════════════════════')
    end, false)
    
    Config.InfoPrint('Commandes de debug Course Poursuite disponibles')
    Config.InfoPrint('- /quit_course : Quitter la partie en cours')
    Config.InfoPrint('- /course_stop : Arrêter le jeu')
    Config.InfoPrint('- /course_info : Afficher les informations')
end

Config.DebugPrint('Fichier client/course_poursuite.lua chargé avec succès')
