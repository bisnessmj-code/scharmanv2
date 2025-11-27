-- ═══════════════════════════════════════════════════════════════
-- SERVER - MODE COURSE POURSUITE V3.3 FINALE (CHASSEUR vs CIBLE)
-- ═══════════════════════════════════════════════════════════════

ESX = exports['es_extended']:getSharedObject()

local activeInstances = {}
local playersInGame = {}
local waitingPlayers = {} -- File d'attente pour matchmaking
local lastUsedBucket = Config.CoursePoursuit.BucketRange.min - 1

-- ═══════════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES
-- ═══════════════════════════════════════════════════════════════

local function GetNextAvailableBucket()
    lastUsedBucket = lastUsedBucket + 1
    if lastUsedBucket > Config.CoursePoursuit.BucketRange.max then
        lastUsedBucket = Config.CoursePoursuit.BucketRange.min
    end
    
    for _, instance in pairs(activeInstances) do
        if instance.bucket == lastUsedBucket then
            return GetNextAvailableBucket()
        end
    end
    
    return lastUsedBucket
end

local function GenerateInstanceId()
    return 'course_' .. os.time() .. '_' .. math.random(1000, 9999)
end

local function GetVehicleModel()
    if Config.CoursePoursuit.RandomVehicle and #Config.CoursePoursuit.VehicleList > 0 then
        return Config.CoursePoursuit.VehicleList[math.random(1, #Config.CoursePoursuit.VehicleList)]
    end
    return Config.CoursePoursuit.VehicleModel
end

-- ═══════════════════════════════════════════════════════════════
-- GESTION INSTANCES
-- ═══════════════════════════════════════════════════════════════

local function CreateInstance(chasseurId, cibleId)
    local instanceCount = 0
    for _ in pairs(activeInstances) do instanceCount = instanceCount + 1 end
    
    if instanceCount >= Config.CoursePoursuit.MaxInstances then
        Config.ErrorPrint('Nombre max instances atteint')
        return nil
    end
    
    local instanceId = GenerateInstanceId()
    local bucket = GetNextAvailableBucket()
    
    local instance = {
        id = instanceId,
        bucket = bucket,
        players = {
            chasseur = chasseurId,
            cible = cibleId
        },
        createdAt = os.time(),
        vehicleModel = GetVehicleModel(),
        warZone = {
            active = false,
            position = nil,
            createdBy = nil
        },
        cibleInZone = false
    }
    
    SetRoutingBucketPopulationEnabled(bucket, false)
    SetRoutingBucketEntityLockdownMode(bucket, Config.CoursePoursuit.BucketLockdown)
    
    activeInstances[instanceId] = instance
    
    Config.SuccessPrint('Instance créée: ' .. instanceId)
    Config.InfoPrint('  Bucket: ' .. bucket)
    Config.InfoPrint('  CHASSEUR: ' .. chasseurId)
    Config.InfoPrint('  CIBLE: ' .. cibleId)
    
    return instance
end

local function DeleteInstance(instanceId)
    local instance = activeInstances[instanceId]
    if not instance then return false end
    
    -- Retirer tous les joueurs
    if instance.players.chasseur then
        RemovePlayerFromInstance(instance.players.chasseur, instanceId)
    end
    
    if instance.players.cible then
        RemovePlayerFromInstance(instance.players.cible, instanceId)
    end
    
    activeInstances[instanceId] = nil
    Config.SuccessPrint('Instance supprimée: ' .. instanceId)
    
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- GESTION JOUEURS
-- ═══════════════════════════════════════════════════════════════

local function AddPlayerToInstance(playerId, instance, role)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    
    if playersInGame[playerId] then return false end
    
    local opponentId = (role == 'chasseur') and instance.players.cible or instance.players.chasseur
    
    playersInGame[playerId] = {
        instanceId = instance.id,
        bucket = instance.bucket,
        originalBucket = GetPlayerRoutingBucket(playerId),
        joinedAt = os.time(),
        role = role,
        opponentId = opponentId
    }
    
    SetPlayerRoutingBucket(playerId, instance.bucket)
    Wait(1000)
    
    -- Créer véhicule pour ce joueur
    local success, vehicleNetId = pcall(function()
        local spawnCoords = Config.CoursePoursuit.SpawnCoords[role]
        local vehicleHash = GetHashKey(instance.vehicleModel)
        
        local vehicle = CreateVehicle(vehicleHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, true)
        Wait(500)
        
        if not DoesEntityExist(vehicle) then
            error('[SERVER] Échec création véhicule')
        end
        
        SetEntityRoutingBucket(vehicle, instance.bucket)
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        
        if netId == 0 or netId == nil then
            DeleteEntity(vehicle)
            error('[SERVER] Échec récupération Network ID')
        end
        
        Config.SuccessPrint('[SERVER] Véhicule créé pour ' .. string.upper(role) .. ': ' .. vehicle .. ' NetID: ' .. netId)
        return netId
    end)
    
    if not success then
        Config.ErrorPrint('[SERVER] Erreur véhicule: ' .. tostring(vehicleNetId))
        playersInGame[playerId] = nil
        SetPlayerRoutingBucket(playerId, 0)
        TriggerClientEvent('scharman:client:courseNotification', playerId, '❌ Erreur création véhicule', 5000, 'error')
        return false
    end
    
    -- Lancer le jeu pour ce joueur
    TriggerClientEvent('scharman:client:startCoursePoursuit', playerId, {
        instanceId = instance.id,
        spawnCoords = Config.CoursePoursuit.SpawnCoords[role],
        vehicleModel = instance.vehicleModel,
        bucketId = instance.bucket,
        vehicleNetId = vehicleNetId,
        role = role,
        opponentId = opponentId
    })
    
    Config.SuccessPrint('Joueur ' .. playerId .. ' ajouté à l\'instance (Rôle: ' .. string.upper(role) .. ')')
    
    return true
end

function RemovePlayerFromInstance(playerId, instanceId)
    local playerData = playersInGame[playerId]
    if not playerData then return false end
    
    local instance = activeInstances[instanceId or playerData.instanceId]
    if not instance then return false end
    
    local xPlayer = ESX.GetPlayerFromId(playerId)
    local playerName = xPlayer and xPlayer.getName() or 'Inconnu'
    
    SetPlayerRoutingBucket(playerId, playerData.originalBucket or 0)
    
    -- Informer l'adversaire
    local opponentId = playerData.opponentId
    if opponentId and playersInGame[opponentId] then
        TriggerClientEvent('scharman:client:courseNotification', opponentId, 
            string.format(Config.CoursePoursuit.Notifications.playerLeft, playerName), 3000)
        
        -- Terminer la partie pour l'adversaire (victoire par abandon)
        TriggerClientEvent('scharman:client:stopCoursePoursuit', opponentId, true)
    end
    
    playersInGame[playerId] = nil
    
    TriggerClientEvent('scharman:client:stopCoursePoursuit', playerId)
    
    -- Supprimer instance si vide
    DeleteInstance(instance.id)
    
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- MATCHMAKING
-- ═══════════════════════════════════════════════════════════════

local function FindOpponent(playerId)
    -- Chercher dans la file d'attente
    for i, waitingPlayerId in ipairs(waitingPlayers) do
        if waitingPlayerId ~= playerId and GetPlayerPing(waitingPlayerId) > 0 then
            -- Adversaire trouvé!
            table.remove(waitingPlayers, i)
            return waitingPlayerId
        end
    end
    
    return nil
end

local function StartMatchmaking(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    Config.InfoPrint('MATCHMAKING: Joueur ' .. playerId .. ' (' .. xPlayer.getName() .. ')')
    Config.InfoPrint('═══════════════════════════════════════════════════════════════')
    
    -- Notifier recherche
    TriggerClientEvent('scharman:client:courseNotification', playerId, 
        Config.CoursePoursuit.Notifications.searching, 5000, 'info')
    
    -- Chercher un adversaire
    local opponentId = FindOpponent(playerId)
    
    if opponentId then
        -- Adversaire trouvé!
        Config.SuccessPrint('MATCH TROUVÉ: ' .. playerId .. ' vs ' .. opponentId)
        
        local xOpponent = ESX.GetPlayerFromId(opponentId)
        
        -- Notifier les deux joueurs
        TriggerClientEvent('scharman:client:courseNotification', playerId, 
            Config.CoursePoursuit.Notifications.playerFound, 3000, 'success')
        TriggerClientEvent('scharman:client:courseNotification', opponentId, 
            Config.CoursePoursuit.Notifications.playerFound, 3000, 'success')
        
        -- IMPORTANT: Attribution des rôles
        -- Le PREMIER joueur (celui qui a cliqué) = CHASSEUR
        -- Le DEUXIÈME joueur (celui en attente) = CIBLE
        local chasseurId = opponentId -- L'adversaire qui attendait devient CHASSEUR
        local cibleId = playerId      -- Le nouveau joueur devient CIBLE
        
        -- Créer instance
        local instance = CreateInstance(chasseurId, cibleId)
        
        if not instance then
            TriggerClientEvent('scharman:client:courseNotification', playerId, 
                Config.CoursePoursuit.Notifications.errorCreatingInstance, 3000, 'error')
            TriggerClientEvent('scharman:client:courseNotification', opponentId, 
                Config.CoursePoursuit.Notifications.errorCreatingInstance, 3000, 'error')
            return
        end
        
        -- Ajouter les deux joueurs avec leurs rôles
        Wait(500)
        AddPlayerToInstance(chasseurId, instance, 'chasseur')
        Wait(500)
        AddPlayerToInstance(cibleId, instance, 'cible')
        
        Config.SuccessPrint('PARTIE LANCÉE:')
        Config.InfoPrint('  CHASSEUR: ' .. xOpponent.getName() .. ' [' .. opponentId .. ']')
        Config.InfoPrint('  CIBLE: ' .. xPlayer.getName() .. ' [' .. playerId .. ']')
    else
        -- Aucun adversaire, ajouter à la file d'attente
        Config.InfoPrint('Aucun adversaire trouvé, ajout file d\'attente')
        table.insert(waitingPlayers, playerId)
        
        TriggerClientEvent('scharman:client:courseNotification', playerId, 
            '⏳ En attente d\'un adversaire...', 5000, 'info')
    end
end

-- ═══════════════════════════════════════════════════════════════
-- GESTION ZONE DE GUERRE
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('scharman:server:zoneCreated', function(instanceId, position)
    local source = source
    local instance = activeInstances[instanceId]
    
    if not instance then
        Config.ErrorPrint('[ZONE] Instance introuvable: ' .. tostring(instanceId))
        return
    end
    
    local playerData = playersInGame[source]
    if not playerData then
        Config.ErrorPrint('[ZONE] Joueur introuvable: ' .. source)
        return
    end
    
    -- VÉRIFICATION: Seul le CHASSEUR peut créer la zone
    if playerData.role ~= 'chasseur' then
        Config.ErrorPrint('[ZONE] ⚠️ TENTATIVE CRÉATION PAR CIBLE - BLOQUÉ!')
        return
    end
    
    Config.InfoPrint('[ZONE] 🔴 ZONE CRÉÉE par CHASSEUR ' .. source)
    Config.DebugPrint('[ZONE] Position: ' .. tostring(position))
    
    -- Enregistrer la zone
    instance.warZone.active = true
    instance.warZone.position = position
    instance.warZone.createdBy = source
    
    -- Informer la CIBLE
    local cibleId = instance.players.cible
    if cibleId and cibleId ~= source then
        Config.InfoPrint('[ZONE] Notification CIBLE: ' .. cibleId)
        TriggerClientEvent('scharman:client:opponentCreatedZone', cibleId, position)
    else
        Config.ErrorPrint('[ZONE] CIBLE introuvable!')
    end
end)

RegisterNetEvent('scharman:server:playerEnteredZone', function(instanceId)
    local source = source
    local instance = activeInstances[instanceId]
    
    if not instance then
        Config.ErrorPrint('[ZONE] Instance introuvable: ' .. tostring(instanceId))
        return
    end
    
    local playerData = playersInGame[source]
    if not playerData then
        Config.ErrorPrint('[ZONE] Joueur introuvable: ' .. source)
        return
    end
    
    -- VÉRIFICATION: Seule la CIBLE peut rejoindre la zone
    if playerData.role ~= 'cible' then
        Config.ErrorPrint('[ZONE] ⚠️ TENTATIVE ENTRÉE PAR CHASSEUR - IGNORÉ!')
        return
    end
    
    Config.InfoPrint('[ZONE] ✅ CIBLE ' .. source .. ' a rejoint la zone')
    
    -- Marquer la cible comme dans la zone
    instance.cibleInZone = true
    
    -- Informer le CHASSEUR
    local chasseurId = instance.players.chasseur
    if chasseurId and chasseurId ~= source then
        Config.InfoPrint('[ZONE] Notification CHASSEUR: ' .. chasseurId)
        TriggerClientEvent('scharman:client:opponentEnteredZone', chasseurId)
    else
        Config.ErrorPrint('[ZONE] CHASSEUR introuvable!')
    end
end)

RegisterNetEvent('scharman:server:playerDied', function(instanceId)
    local source = source
    local instance = activeInstances[instanceId]
    
    if not instance then return end
    
    local playerData = playersInGame[source]
    if not playerData then return end
    
    Config.InfoPrint('💀 Joueur ' .. source .. ' (' .. string.upper(playerData.role) .. ') est mort')
    
    -- Informer l'adversaire de sa victoire
    local opponentId = playerData.opponentId
    if opponentId then
        Config.InfoPrint('🏆 Victoire pour: ' .. opponentId)
        TriggerClientEvent('scharman:client:opponentDied', opponentId)
    end
    
    -- Terminer la partie pour le joueur mort (défaite)
    Wait(3000)
    TriggerClientEvent('scharman:client:stopCoursePoursuit', source, false)
    
    -- Supprimer l'instance
    Wait(5000)
    DeleteInstance(instanceId)
end)

-- ═══════════════════════════════════════════════════════════════
-- ÉVÉNEMENTS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('scharman:server:joinCoursePoursuit', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    if not Config.CoursePoursuit.Enabled then
        TriggerClientEvent('scharman:client:courseNotification', source, '❌ Mode désactivé', 3000)
        return
    end
    
    -- Vérifier si déjà en jeu
    if playersInGame[source] then
        TriggerClientEvent('scharman:client:courseNotification', source, '❌ Vous êtes déjà en partie', 3000)
        return
    end
    
    -- Vérifier si déjà en file d'attente
    for _, waitingId in ipairs(waitingPlayers) do
        if waitingId == source then
            TriggerClientEvent('scharman:client:courseNotification', source, '⏳ Déjà en file d\'attente', 3000)
            return
        end
    end
    
    -- Lancer matchmaking
    StartMatchmaking(source)
end)

RegisterNetEvent('scharman:server:coursePoursuiteLeft', function()
    local source = source
    local playerData = playersInGame[source]
    
    if playerData then
        RemovePlayerFromInstance(source, playerData.instanceId)
    end
    
    -- Retirer de la file d'attente si présent
    for i, waitingId in ipairs(waitingPlayers) do
        if waitingId == source then
            table.remove(waitingPlayers, i)
            Config.InfoPrint('Joueur ' .. source .. ' retiré de la file d\'attente')
            break
        end
    end
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    local playerData = playersInGame[source]
    
    if playerData then
        RemovePlayerFromInstance(source, playerData.instanceId)
    end
    
    -- Retirer de la file d'attente
    for i, waitingId in ipairs(waitingPlayers) do
        if waitingId == source then
            table.remove(waitingPlayers, i)
            break
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- COMMANDES ADMIN
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('course_instances', function(source, args, rawCommand)
    if source > 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or xPlayer.getGroup() ~= 'admin' then return end
    end
    
    print('═══════════════════════════════════════════════════════════════')
    print('Instances Course Poursuite actives:')
    local count = 0
    for instanceId, instance in pairs(activeInstances) do
        count = count + 1
        print(string.format('%d. Instance: %s (Bucket: %d)', count, instanceId, instance.bucket))
        print(string.format('   CHASSEUR: %d | CIBLE: %d', instance.players.chasseur, instance.players.cible))
        print(string.format('   Véhicule: %s', instance.vehicleModel))
        print(string.format('   Zone active: %s', instance.warZone.active and 'OUI' or 'NON'))
        if instance.warZone.active then
            print(string.format('   Zone créée par: %s (CHASSEUR)', instance.warZone.createdBy))
            print(string.format('   CIBLE dans zone: %s', instance.cibleInZone and 'OUI' or 'NON'))
        end
    end
    if count == 0 then print('Aucune instance active') end
    print('═══════════════════════════════════════════════════════════════')
    print('File d\'attente:')
    if #waitingPlayers > 0 then
        for i, playerId in ipairs(waitingPlayers) do
            local xPlayer = ESX.GetPlayerFromId(playerId)
            local name = xPlayer and xPlayer.getName() or 'Inconnu'
            print(string.format('%d. %s [ID: %d]', i, name, playerId))
        end
    else
        print('Aucun joueur en attente')
    end
    print('═══════════════════════════════════════════════════════════════')
end, true)

RegisterCommand('course_kick', function(source, args, rawCommand)
    if source > 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or xPlayer.getGroup() ~= 'admin' then return end
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
        print('Usage: /course_kick [player_id]')
        return
    end
    
    if playersInGame[targetId] then
        RemovePlayerFromInstance(targetId)
        print('Joueur ' .. targetId .. ' éjecté')
    else
        print('Le joueur n\'est pas en jeu')
    end
end, true)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for instanceId, instance in pairs(activeInstances) do
        DeleteInstance(instanceId)
    end
end)

Config.DebugPrint('server/course_poursuite.lua V3.3 FINALE chargé')
