-- ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
-- ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
-- ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
-- ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
-- ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
-- CLIENT - MODE COURSE POURSUITE V3 (PVP 1V1 SYNCHRONISÉ)
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- VARIABLES LOCALES
-- ═══════════════════════════════════════════════════════════════

local inGame = false
local currentVehicle = nil
local instanceId = nil
local currentBucket = 0
local playerNumber = 1 -- 1 ou 2
local opponentId = nil

-- Threads
local blockExitThread = nil
local vehicleExitThread = nil
local damageZoneThread = nil
local warZoneThread = nil
local warningMessageActive = false

-- Timers
local gameEndTime = nil
local gameStartTime = nil

-- Zone de guerre
local canExitVehicle = false
local warZoneActive = false
local warZonePosition = nil
local warZoneBlip = nil
local warZoneCenterBlip = nil
local warZoneRadius = Config.CoursePoursuit.WarZoneRadius
local zoneCreatedByMe = false
local zoneCreatedByOpponent = false
local opponentInZone = false
local iAmInZone = false

-- Bot (mode test uniquement)
local botPed = nil
local botVehicle = nil
local botMode = false

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
    
    Config.DebugPrint('Chargement modèle: ' .. model)
    RequestModel(modelHash)
    
    local timeout = 0
    while not HasModelLoaded(modelHash) do
        Wait(100)
        timeout = timeout + 100
        
        if timeout >= 10000 then
            Config.ErrorPrint('Timeout chargement modèle: ' .. model)
            return false
        end
    end
    
    Config.SuccessPrint('Modèle chargé: ' .. model)
    return true
end

local function ForcePlayerIntoVehicle(ped, vehicle, seat)
    Config.DebugPrint('Placement joueur dans véhicule...')
    
    if not DoesEntityExist(vehicle) or not DoesEntityExist(ped) then
        Config.ErrorPrint('Véhicule ou PED inexistant!')
        return false
    end
    
    SetVehicleOnGroundProperly(vehicle)
    Wait(100)
    
    TaskWarpPedIntoVehicle(ped, vehicle, seat)
    Wait(500)
    
    local attempts = 0
    local maxAttempts = 10
    
    while GetVehiclePedIsIn(ped, false) ~= vehicle and attempts < maxAttempts do
        attempts = attempts + 1
        Config.DebugPrint('Tentative ' .. attempts .. '/' .. maxAttempts)
        
        TaskWarpPedIntoVehicle(ped, vehicle, seat)
        Wait(300)
        
        if GetVehiclePedIsIn(ped, false) ~= vehicle then
            SetPedIntoVehicle(ped, vehicle, seat)
            Wait(300)
        end
    end
    
    local isInVehicle = GetVehiclePedIsIn(ped, false) == vehicle
    
    if isInVehicle then
        Config.SuccessPrint('Joueur placé dans véhicule!')
        return true
    else
        Config.ErrorPrint('ÉCHEC placement après ' .. attempts .. ' tentatives')
        return false
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ZONE DE GUERRE
-- ═══════════════════════════════════════════════════════════════

local function CreateWarZoneVisuals(position)
    -- Créer le blip de rayon (zone rouge)
    if warZoneBlip then
        RemoveBlip(warZoneBlip)
    end
    
    warZoneBlip = AddBlipForRadius(position.x, position.y, position.z, warZoneRadius)
    SetBlipHighDetail(warZoneBlip, true)
    SetBlipColour(warZoneBlip, Config.CoursePoursuit.WarZoneBlipColor)
    SetBlipAlpha(warZoneBlip, 180)
    
    -- Créer le blip centre (crâne)
    if warZoneCenterBlip then
        RemoveBlip(warZoneCenterBlip)
    end
    
    warZoneCenterBlip = AddBlipForCoord(position.x, position.y, position.z)
    SetBlipSprite(warZoneCenterBlip, Config.CoursePoursuit.WarZoneBlipSprite)
    SetBlipDisplay(warZoneCenterBlip, 4)
    SetBlipScale(warZoneCenterBlip, 1.2)
    SetBlipColour(warZoneCenterBlip, Config.CoursePoursuit.WarZoneBlipColor)
    SetBlipAsShortRange(warZoneCenterBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("🔴 ZONE DE GUERRE")
    EndTextCommandSetBlipName(warZoneCenterBlip)
    
    Config.SuccessPrint('Visuels zone de guerre créés')
end

local function StartWarZoneThread()
    if warZoneThread then return end
    
    Config.InfoPrint('Thread rendu zone démarré')
    
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
                warZoneRadius, warZoneRadius, Config.CoursePoursuit.WarZoneLightHeight,
                Config.CoursePoursuit.WarZoneColor.r,
                Config.CoursePoursuit.WarZoneColor.g,
                Config.CoursePoursuit.WarZoneColor.b,
                Config.CoursePoursuit.WarZoneColor.a,
                false, false, 2, false, nil, nil, false
            )
            
            -- Cercle au sol
            DrawMarker(
                1,
                pos.x, pos.y, pos.z - 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                warZoneRadius * 2, warZoneRadius * 2, 1.0,
                Config.CoursePoursuit.WarZoneColor.r,
                Config.CoursePoursuit.WarZoneColor.g,
                Config.CoursePoursuit.WarZoneColor.b,
                150,
                false, false, 2, false, nil, nil, false
            )
            
            ::continue::
        end
        
        warZoneThread = nil
        Config.DebugPrint('Thread rendu zone arrêté')
    end)
end

local function CreateWarZone(position)
    Config.InfoPrint('🔴 CRÉATION ZONE DE GUERRE')
    Config.DebugPrint('[ZONE] Position: ' .. tostring(position))
    
    warZonePosition = position
    warZoneActive = true
    zoneCreatedByMe = true
    
    CreateWarZoneVisuals(position)
    StartWarZoneThread()
    
    -- Informer le serveur
    TriggerServerEvent('scharman:server:zoneCreated', instanceId, position)
    
    ShowGameNotification(Config.CoursePoursuit.Notifications.warZoneCreated, 5000, 'warning')
    
    Config.SuccessPrint('Zone créée à: ' .. tostring(position))
end

local function DeleteWarZone()
    Config.DebugPrint('Suppression zone de guerre...')
    
    warZoneActive = false
    warZonePosition = nil
    zoneCreatedByMe = false
    zoneCreatedByOpponent = false
    opponentInZone = false
    iAmInZone = false
    
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
    
    Config.SuccessPrint('Zone supprimée')
end

-- ═══════════════════════════════════════════════════════════════
-- DÉCOMPTE 3-2-1-GO
-- ═══════════════════════════════════════════════════════════════

local function StartCountdown()
    Config.InfoPrint('⏱️ DÉCOMPTE 3-2-1-GO')
    
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    
    -- 3
    SendNUIMessage({ action = 'showCountdown', data = { number = 3 } })
    PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
    Wait(1000)
    
    -- 2
    SendNUIMessage({ action = 'showCountdown', data = { number = 2 } })
    PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
    Wait(1000)
    
    -- 1
    SendNUIMessage({ action = 'showCountdown', data = { number = 1 } })
    PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
    Wait(1000)
    
    -- GO!
    SendNUIMessage({ action = 'showCountdown', data = { number = 'GO!' } })
    PlaySoundFrontend(-1, 'RACE_PLACED', 'HUD_AWARDS', true)
    
    FreezeEntityPosition(ped, false)
    Wait(1000)
    
    SendNUIMessage({ action = 'hideCountdown' })
    Config.SuccessPrint('✅ Décompte terminé!')
end

-- ═══════════════════════════════════════════════════════════════
-- GESTION BOT (MODE TEST)
-- ═══════════════════════════════════════════════════════════════

local function DeleteBot()
    if DoesEntityExist(botVehicle) then
        DeleteEntity(botVehicle)
        botVehicle = nil
    end
    
    if DoesEntityExist(botPed) then
        DeleteEntity(botPed)
        botPed = nil
    end
    
    Config.SuccessPrint('Bot supprimé')
end

local function SpawnBot()
    Config.InfoPrint('🤖 SPAWN BOT (MODE TEST)')
    
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local playerHeading = GetEntityHeading(ped)
    
    -- Calcul position spawn
    local offset = Config.CoursePoursuit.Bot.spawnOffset
    local forwardX = math.cos(math.rad(playerHeading))
    local forwardY = math.sin(math.rad(playerHeading))
    
    local botCoords = vector3(
        playerCoords.x + (forwardX * offset.x) + offset.y,
        playerCoords.y + (forwardY * offset.x),
        playerCoords.z + offset.z
    )
    
    -- Charger modèle PED
    if not LoadModel(Config.CoursePoursuit.Bot.model) then
        return false
    end
    
    local modelHash = GetHashKey(Config.CoursePoursuit.Bot.model)
    
    -- Créer PED LOCAL
    botPed = CreatePed(4, modelHash, botCoords.x, botCoords.y, botCoords.z, playerHeading, false, false)
    
    if not DoesEntityExist(botPed) then
        Config.ErrorPrint('Échec création bot')
        return false
    end
    
    SetEntityInvincible(botPed, true)
    SetBlockingOfNonTemporaryEvents(botPed, true)
    SetPedCanRagdoll(botPed, false)
    
    Wait(500)
    
    -- Charger véhicule
    if not LoadModel(Config.CoursePoursuit.Bot.vehicle) then
        DeleteEntity(botPed)
        return false
    end
    
    local vehicleHash = GetHashKey(Config.CoursePoursuit.Bot.vehicle)
    botVehicle = CreateVehicle(vehicleHash, botCoords.x, botCoords.y, botCoords.z, playerHeading, false, false)
    
    if not DoesEntityExist(botVehicle) then
        Config.ErrorPrint('Échec création véhicule bot')
        DeleteEntity(botPed)
        return false
    end
    
    local botColor = Config.CoursePoursuit.Bot.vehicleColor
    SetVehicleCustomPrimaryColour(botVehicle, botColor.primary.r, botColor.primary.g, botColor.primary.b)
    SetVehicleCustomSecondaryColour(botVehicle, botColor.secondary.r, botColor.secondary.g, botColor.secondary.b)
    SetVehicleNumberPlateText(botVehicle, 'BOT~AI')
    
    Wait(1000)
    
    -- Placer bot dans véhicule
    TaskWarpPedIntoVehicle(botPed, botVehicle, -1)
    Wait(1000)
    
    -- Conduite aléatoire
    if Config.CoursePoursuit.Bot.randomRoute then
        TaskVehicleDriveWander(botPed, botVehicle, Config.CoursePoursuit.Bot.speed, Config.CoursePoursuit.Bot.drivingStyle)
    end
    
    Config.SuccessPrint('🤖 Bot spawné!')
    ShowGameNotification('🤖 Bot adversaire spawné !', 4000, 'success')
    
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- THREAD DÉGÂTS ZONE
-- ═══════════════════════════════════════════════════════════════

local function StartDamageZoneThread()
    if damageZoneThread then return end
    
    Config.InfoPrint('[DAMAGE] 🔴 Démarrage thread dégâts')
    
    damageZoneThread = CreateThread(function()
        while inGame and warZoneActive do
            Wait(Config.CoursePoursuit.DamageInterval)
            
            if not warZonePosition then
                goto continue
            end
            
            local ped = PlayerPedId()
            
            -- Vérifier mort
            if IsEntityDead(ped) or GetEntityHealth(ped) <= 0 then
                Config.InfoPrint('[DAMAGE] 💀 Joueur mort')
                
                SendNUIMessage({ action = 'showDeathScreen' })
                Wait(3000)
                
                -- Informer serveur de la mort
                TriggerServerEvent('scharman:server:playerDied', instanceId)
                
                break
            end
            
            local playerCoords = GetEntityCoords(ped)
            local distance = #(playerCoords - vector3(warZonePosition.x, warZonePosition.y, warZonePosition.z))
            
            -- Si hors zone
            if distance > warZoneRadius then
                local currentHealth = GetEntityHealth(ped)
                local newHealth = currentHealth - Config.CoursePoursuit.OutOfZoneDamage
                
                Config.InfoPrint(string.format('[DAMAGE] ⚡ HORS ZONE! Distance: %.1fm | HP: %d → %d', distance, currentHealth, newHealth))
                
                -- Message d'avertissement
                if not warningMessageActive then
                    warningMessageActive = true
                    
                    CreateThread(function()
                        while inGame and distance > warZoneRadius do
                            ShowGameNotification(Config.CoursePoursuit.Notifications.outOfZone, 1500, 'warning')
                            Wait(2000)
                            
                            local newCoords = GetEntityCoords(PlayerPedId())
                            distance = #(newCoords - vector3(warZonePosition.x, warZonePosition.y, warZonePosition.z))
                        end
                        
                        warningMessageActive = false
                        ShowGameNotification('✅ Retour dans la zone!', 2000, 'success')
                    end)
                end
                
                -- Infliger dégâts
                SetEntityHealth(ped, math.max(0, newHealth))
                ShowGameNotification(string.format(Config.CoursePoursuit.Notifications.takingDamage, Config.CoursePoursuit.OutOfZoneDamage), 1500, 'error')
            else
                warningMessageActive = false
            end
            
            ::continue::
        end
        
        damageZoneThread = nil
        Config.InfoPrint('[DAMAGE] 🔴 Thread dégâts arrêté')
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- THREAD BLOCAGE SORTIE VÉHICULE
-- ═══════════════════════════════════════════════════════════════

local function StartBlockExitThread()
    if blockExitThread then return end
    
    Config.DebugPrint('Thread blocage sortie démarré')
    
    -- Timer 30 secondes
    CreateThread(function()
        SendNUIMessage({
            action = 'showVehicleLock',
            data = { duration = Config.CoursePoursuit.BlockExitDuration * 1000 }
        })
        
        Wait(Config.CoursePoursuit.BlockExitDuration * 1000)
        
        canExitVehicle = true
        
        SendNUIMessage({ action = 'hideVehicleLock' })
        
        Config.SuccessPrint('✅ Sortie véhicule autorisée!')
        ShowGameNotification(Config.CoursePoursuit.Notifications.canExitVehicle, 5000, 'success')
    end)
    
    blockExitThread = CreateThread(function()
        while inGame and Config.CoursePoursuit.BlockExitVehicle do
            Wait(0)
            
            local ped = PlayerPedId()
            local isInVehicle = IsPedInVehicle(ped, currentVehicle, false)
            
            if not canExitVehicle then
                DisableControlAction(0, 75, true)
                
                if IsDisabledControlJustPressed(0, 75) then
                    local timeElapsed = (GetGameTimer() - gameStartTime) / 1000
                    local timeLeft = math.max(0, Config.CoursePoursuit.BlockExitDuration - timeElapsed)
                    ShowGameNotification(string.format('⏰ Attendez encore %d secondes!', math.ceil(timeLeft)), 3000, 'warning')
                end
                
                if DoesEntityExist(currentVehicle) and not isInVehicle then
                    ForcePlayerIntoVehicle(ped, currentVehicle, -1)
                    ShowGameNotification('🚗 Retour forcé - Attendez', 3000, 'warning')
                end
            end
        end
        
        blockExitThread = nil
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- THREAD DÉTECTION SORTIE VÉHICULE
-- ═══════════════════════════════════════════════════════════════

local function StartVehicleExitDetectionThread()
    if vehicleExitThread then return end
    
    vehicleExitThread = CreateThread(function()
        Config.DebugPrint('Thread détection sortie démarré')
        
        while inGame and not zoneCreatedByMe do
            Wait(500)
            
            local ped = PlayerPedId()
            
            -- Si peut sortir ET n'est PAS dans véhicule
            if canExitVehicle and not IsPedInAnyVehicle(ped, false) then
                -- Créer zone de guerre
                local coords = GetEntityCoords(ped)
                CreateWarZone(coords)
                
                -- Donner arme
                local weaponHash = GetHashKey(Config.CoursePoursuit.WeaponHash)
                GiveWeaponToPed(ped, weaponHash, Config.CoursePoursuit.WeaponAmmo, false, true)
                SetCurrentPedWeapon(ped, weaponHash, true)
                
                ShowGameNotification(Config.CoursePoursuit.Notifications.weaponGiven, 3000, 'success')
                Config.SuccessPrint('Zone créée & arme donnée')
                
                -- Démarrer thread dégâts
                StartDamageZoneThread()
                
                break
            end
        end
        
        vehicleExitThread = nil
        Config.DebugPrint('Thread détection sortie arrêté')
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- THREAD VÉRIFICATION PRÉSENCE DANS ZONE (pour adversaire)
-- ═══════════════════════════════════════════════════════════════

local function StartZonePresenceCheckThread()
    CreateThread(function()
        while inGame and zoneCreatedByOpponent and not iAmInZone do
            Wait(500)
            
            if not warZonePosition then
                goto continue
            end
            
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)
            local distance = #(playerCoords - vector3(warZonePosition.x, warZonePosition.y, warZonePosition.z))
            
            -- Si dans la zone
            if distance <= warZoneRadius then
                iAmInZone = true
                canExitVehicle = true -- Autoriser sortie
                
                Config.SuccessPrint('✅ Je suis dans la zone adverse!')
                
                -- Informer serveur
                TriggerServerEvent('scharman:server:playerEnteredZone', instanceId)
                
                ShowGameNotification('✅ Zone rejointe ! Vous pouvez descendre !', 5000, 'success')
                
                -- Donner arme si descendu
                if not IsPedInAnyVehicle(ped, false) then
                    local weaponHash = GetHashKey(Config.CoursePoursuit.WeaponHash)
                    GiveWeaponToPed(ped, weaponHash, Config.CoursePoursuit.WeaponAmmo, false, true)
                    SetCurrentPedWeapon(ped, weaponHash, true)
                    ShowGameNotification(Config.CoursePoursuit.Notifications.weaponGiven, 3000, 'success')
                end
                
                break
            end
            
            ::continue::
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- DÉMARRAGE JEU
-- ═══════════════════════════════════════════════════════════════

local function StartCoursePoursuiteGame(data)
    if inGame then return end
    
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    Config.InfoPrint('DÉMARRAGE COURSE POURSUITE V3 (PVP 1V1)')
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    
    local success, err = pcall(function()
        local ped = PlayerPedId()
        instanceId = data.instanceId
        playerNumber = data.playerNumber
        opponentId = data.opponentId
        botMode = data.botMode or false
        
        -- Sélection spawn
        local spawnCoords = data.spawnCoords or (playerNumber == 1 and Config.CoursePoursuit.SpawnCoords.player1 or Config.CoursePoursuit.SpawnCoords.player2)
        local vehicleModel = data.vehicleModel or Config.CoursePoursuit.VehicleModel
        
        ShowGameNotification(Config.CoursePoursuit.Notifications.teleporting, 2000, 'info')
        
        DoScreenFadeOut(800)
        while not IsScreenFadedOut() do Wait(10) end
        
        SetEntityCoords(ped, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, true)
        SetEntityHeading(ped, spawnCoords.w)
        
        -- Stocker bucket
        currentBucket = data.bucketId or 0
        
        if currentBucket > 0 then
            Config.InfoPrint('Synchronisation bucket ' .. currentBucket)
            Wait(3000)
            Config.SuccessPrint('Synchro terminée')
        else
            Wait(3000)
        end
        
        Wait(1000)
        
        -- Récupération véhicule
        local vehicleNetId = data.vehicleNetId
        
        if vehicleNetId then
            Config.InfoPrint('═══ RÉCUPÉRATION VÉHICULE ═══')
            
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
            until attempt >= maxAttempts
            
            if not currentVehicle or not DoesEntityExist(currentVehicle) then
                error('Échec récupération véhicule')
            end
            
            SetVehicleOnGroundProperly(currentVehicle)
            Wait(500)
        end
        
        -- Personnalisation véhicule
        local customization = playerNumber == 1 and Config.CoursePoursuit.VehicleCustomization.player1 or Config.CoursePoursuit.VehicleCustomization.player2
        SetVehicleCustomPrimaryColour(currentVehicle, customization.primaryColor.r, customization.primaryColor.g, customization.primaryColor.b)
        SetVehicleCustomSecondaryColour(currentVehicle, customization.secondaryColor.r, customization.secondaryColor.g, customization.secondaryColor.b)
        SetVehicleNumberPlateText(currentVehicle, customization.plate)
        
        local mods = Config.CoursePoursuit.VehicleCustomization.mods
        SetVehicleMod(currentVehicle, 11, mods.engine, false)
        SetVehicleMod(currentVehicle, 12, mods.brakes, false)
        SetVehicleMod(currentVehicle, 13, mods.transmission, false)
        SetVehicleMod(currentVehicle, 15, mods.suspension, false)
        ToggleVehicleMod(currentVehicle, 18, mods.turbo)
        
        SetVehicleEngineHealth(currentVehicle, 1000.0)
        SetVehicleBodyHealth(currentVehicle, 1000.0)
        SetVehicleDoorsLocked(currentVehicle, 2)
        
        Config.SuccessPrint('Véhicule personnalisé')
        
        -- Placement joueur
        Config.InfoPrint('═══ PLACEMENT JOUEUR ═══')
        local placementSuccess = ForcePlayerIntoVehicle(ped, currentVehicle, -1)
        
        if not placementSuccess then
            error('Impossible de placer joueur')
        end
        
        -- Fade in
        DoScreenFadeIn(500)
        while not IsScreenFadedIn() do Wait(10) end
        
        inGame = true
        gameStartTime = GetGameTimer()
        
        -- Décompte
        if Config.CoursePoursuit.EnableCountdown then
            StartCountdown()
        end
        
        -- Timer fin de jeu
        if Config.CoursePoursuit.GameDuration > 0 then
            gameEndTime = GetGameTimer() + (Config.CoursePoursuit.GameDuration * 1000)
        end
        
        -- Spawner bot si mode test
        if botMode then
            Config.InfoPrint('MODE BOT ACTIVÉ')
            Wait(2000)
            SpawnBot()
        end
        
        -- Démarrer threads
        StartBlockExitThread()
        StartVehicleExitDetectionThread()
        
        Config.SuccessPrint('PARTIE DÉMARRÉE!')
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
-- ARRÊT JEU
-- ═══════════════════════════════════════════════════════════════

local function StopCoursePoursuiteGame(showVictory)
    if not inGame then return end
    
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    Config.InfoPrint('ARRÊT COURSE POURSUITE V3')
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    
    inGame = false
    blockExitThread = nil
    vehicleExitThread = nil
    damageZoneThread = nil
    gameEndTime = nil
    gameStartTime = nil
    canExitVehicle = false
    zoneCreatedByMe = false
    zoneCreatedByOpponent = false
    opponentInZone = false
    iAmInZone = false
    currentBucket = 0
    warningMessageActive = false
    playerNumber = 1
    opponentId = nil
    botMode = false
    
    -- Masquer écrans
    SendNUIMessage({ action = 'hideDeathScreen' })
    SendNUIMessage({ action = 'hideVehicleLock' })
    
    -- Supprimer zone
    DeleteWarZone()
    
    local ped = PlayerPedId()
    
    -- Retirer armes
    RemoveAllPedWeapons(ped, true)
    
    -- Téléportation retour
    if Config.CoursePoursuit.ReturnToNormalCoords then
        DoScreenFadeOut(500)
        Wait(500)
        
        local returnCoords = Config.CoursePoursuit.ReturnToNormalCoords
        SetEntityCoords(ped, returnCoords.x, returnCoords.y, returnCoords.z, false, false, false, true)
        SetEntityHeading(ped, returnCoords.w)
        
        -- Ressusciter si mort
        if IsEntityDead(ped) or GetEntityHealth(ped) <= 0 then
            NetworkResurrectLocalPlayer(returnCoords.x, returnCoords.y, returnCoords.z, returnCoords.w, true, false)
            SetEntityHealth(ped, 200)
            ClearPedTasksImmediately(ped)
        end
        
        Wait(500)
        
        -- Message victoire/défaite
        if showVictory ~= nil then
            if showVictory then
                ShowGameNotification(Config.CoursePoursuit.Notifications.youWon, 5000, 'success')
            else
                ShowGameNotification(Config.CoursePoursuit.Notifications.youLost, 5000, 'error')
            end
        end
        
        DoScreenFadeIn(500)
    end
    
    -- Supprimer véhicule
    if DoesEntityExist(currentVehicle) then
        DeleteEntity(currentVehicle)
        currentVehicle = nil
    end
    
    -- Supprimer bot
    DeleteBot()
    
    instanceId = nil
    
    Config.SuccessPrint('NETTOYAGE TERMINÉ')
end

-- ═══════════════════════════════════════════════════════════════
-- ÉVÉNEMENTS RÉSEAU
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('scharman:client:startCoursePoursuit', function(data)
    StartCoursePoursuiteGame(data)
end)

RegisterNetEvent('scharman:client:stopCoursePoursuit', function(showVictory)
    StopCoursePoursuiteGame(showVictory)
end)

RegisterNetEvent('scharman:client:courseNotification', function(message, duration, notifType)
    ShowGameNotification(message, duration or 3000, notifType or 'info')
end)

-- Événement: L'adversaire a créé la zone
RegisterNetEvent('scharman:client:opponentCreatedZone', function(position)
    Config.InfoPrint('⚠️ ADVERSAIRE A CRÉÉ LA ZONE!')
    
    warZonePosition = position
    warZoneActive = true
    zoneCreatedByOpponent = true
    
    CreateWarZoneVisuals(position)
    StartWarZoneThread()
    
    ShowGameNotification(Config.CoursePoursuit.Notifications.opponentCreatedZone, 5000, 'warning')
    ShowGameNotification(Config.CoursePoursuit.Notifications.waitingOpponent, 5000, 'info')
    
    -- Démarrer vérification présence dans zone
    StartZonePresenceCheckThread()
end)

-- Événement: L'adversaire a rejoint la zone
RegisterNetEvent('scharman:client:opponentEnteredZone', function()
    Config.InfoPrint('✅ ADVERSAIRE DANS LA ZONE!')
    
    opponentInZone = true
    canExitVehicle = true
    
    ShowGameNotification(Config.CoursePoursuit.Notifications.opponentInZone, 5000, 'success')
    
    -- Démarrer thread dégâts si pas déjà fait
    if not damageZoneThread and warZoneActive then
        StartDamageZoneThread()
    end
end)

-- Événement: L'adversaire est mort
RegisterNetEvent('scharman:client:opponentDied', function()
    Config.InfoPrint('🏆 ADVERSAIRE MORT - VICTOIRE!')
    
    Wait(2000)
    StopCoursePoursuiteGame(true) -- true = victoire
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

-- Commande admin: Spawner un bot
RegisterCommand('botscharman', function()
    if not inGame then
        ShowGameNotification('❌ Vous devez être en partie', 3000, 'error')
        return
    end
    
    if botMode then
        ShowGameNotification('❌ Un bot existe déjà', 3000, 'error')
        return
    end
    
    botMode = true
    local spawned = SpawnBot()
    
    if spawned then
        ShowGameNotification('✅ Bot spawné en mode test', 3000, 'success')
    else
        ShowGameNotification('❌ Échec spawn bot', 3000, 'error')
        botMode = false
    end
end, false)

if Config.Debug then
    RegisterCommand('course_info', function()
        print('═══════════════════════════════════════════════════════════════')
        print('État: ' .. (inGame and 'EN JEU' or 'PAS EN JEU'))
        print('Instance: ' .. (instanceId or 'Aucune'))
        print('Joueur: ' .. playerNumber .. (opponentId and (' vs ' .. opponentId) or ''))
        print('Véhicule: ' .. (currentVehicle or 'Aucun'))
        print('Bucket: ' .. currentBucket)
        print('Zone active: ' .. (warZoneActive and 'OUI' or 'NON'))
        print('Zone créée par moi: ' .. (zoneCreatedByMe and 'OUI' or 'NON'))
        print('Zone créée par adversaire: ' .. (zoneCreatedByOpponent and 'OUI' or 'NON'))
        print('Adversaire dans zone: ' .. (opponentInZone and 'OUI' or 'NON'))
        print('Je suis dans zone: ' .. (iAmInZone and 'OUI' or 'NON'))
        print('Peut sortir véhicule: ' .. (canExitVehicle and 'OUI' or 'NON'))
        print('Mode bot: ' .. (botMode and 'OUI' or 'NON'))
        print('═══════════════════════════════════════════════════════════════')
    end, false)
end

Config.DebugPrint('client/course_poursuite.lua V3 chargé')
