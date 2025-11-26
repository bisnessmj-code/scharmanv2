-- ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
-- ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
-- ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
-- ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
-- ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
-- SERVER - MODE COURSE POURSUITE (ROUTING BUCKETS)
-- ═══════════════════════════════════════════════════════════════

ESX = exports['es_extended']:getSharedObject()

-- ═══════════════════════════════════════════════════════════════
-- VARIABLES GLOBALES
-- ═══════════════════════════════════════════════════════════════

-- Table des instances actives
local activeInstances = {}

-- Table des joueurs en jeu
local playersInGame = {}

-- Dernier routing bucket utilisé
local lastUsedBucket = Config.CoursePoursuit.BucketRange.min - 1

-- ═══════════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES
-- ═══════════════════════════════════════════════════════════════

-- Obtenir le prochain routing bucket disponible
local function GetNextAvailableBucket()
    lastUsedBucket = lastUsedBucket + 1
    
    if lastUsedBucket > Config.CoursePoursuit.BucketRange.max then
        lastUsedBucket = Config.CoursePoursuit.BucketRange.min
    end
    
    -- Vérifier que le bucket n'est pas déjà utilisé
    for instanceId, instance in pairs(activeInstances) do
        if instance.bucket == lastUsedBucket then
            -- Bucket occupé, essayer le suivant
            return GetNextAvailableBucket()
        end
    end
    
    return lastUsedBucket
end

-- Générer un ID d'instance unique
local function GenerateInstanceId()
    return 'course_' .. os.time() .. '_' .. math.random(1000, 9999)
end

-- Obtenir le modèle de véhicule (aléatoire si configuré)
local function GetVehicleModel()
    if Config.CoursePoursuit.RandomVehicle and #Config.CoursePoursuit.VehicleList > 0 then
        return Config.CoursePoursuit.VehicleList[math.random(1, #Config.CoursePoursuit.VehicleList)]
    end
    return Config.CoursePoursuit.VehicleModel
end

-- ═══════════════════════════════════════════════════════════════
-- GESTION DES INSTANCES
-- ═══════════════════════════════════════════════════════════════

-- Créer une nouvelle instance
local function CreateInstance()
    -- Vérifier le nombre maximum d'instances
    local instanceCount = 0
    for _ in pairs(activeInstances) do
        instanceCount = instanceCount + 1
    end
    
    if instanceCount >= Config.CoursePoursuit.MaxInstances then
        Config.ErrorPrint('Nombre maximum d\'instances atteint')
        return nil
    end
    
    -- Générer l'ID et le bucket
    local instanceId = GenerateInstanceId()
    local bucket = GetNextAvailableBucket()
    
    -- Créer l'instance
    local instance = {
        id = instanceId,
        bucket = bucket,
        players = {},
        createdAt = os.time(),
        maxPlayers = Config.CoursePoursuit.MaxPlayersPerInstance,
        vehicleModel = GetVehicleModel()
    }
    
    -- Configurer le routing bucket
    SetRoutingBucketPopulationEnabled(bucket, false) -- Pas de PNJ
    SetRoutingBucketEntityLockdownMode(bucket, Config.CoursePoursuit.BucketLockdown)
    
    -- Sauvegarder l'instance
    activeInstances[instanceId] = instance
    
    Config.SuccessPrint('Instance créée: ' .. instanceId .. ' (Bucket: ' .. bucket .. ')')
    
    if Config.CoursePoursuit.LogEvents then
        print(string.format('[SCHARMAN] Instance %s créée avec bucket %d', instanceId, bucket))
    end
    
    return instance
end

-- Supprimer une instance
local function DeleteInstance(instanceId)
    local instance = activeInstances[instanceId]
    
    if not instance then
        Config.ErrorPrint('Instance introuvable: ' .. instanceId)
        return false
    end
    
    -- Retirer tous les joueurs de l'instance
    for _, playerId in ipairs(instance.players) do
        RemovePlayerFromInstance(playerId, instanceId)
    end
    
    -- Supprimer l'instance
    activeInstances[instanceId] = nil
    
    Config.SuccessPrint('Instance supprimée: ' .. instanceId)
    
    if Config.CoursePoursuit.LogEvents then
        print(string.format('[SCHARMAN] Instance %s supprimée', instanceId))
    end
    
    return true
end

-- Trouver ou créer une instance disponible
local function FindOrCreateInstance()
    -- Chercher une instance avec de la place
    for instanceId, instance in pairs(activeInstances) do
        if #instance.players < instance.maxPlayers then
            Config.DebugPrint('Instance disponible trouvée: ' .. instanceId)
            return instance
        end
    end
    
    -- Aucune instance disponible, en créer une nouvelle
    Config.InfoPrint('Aucune instance disponible, création d\'une nouvelle...')
    return CreateInstance()
end

-- ═══════════════════════════════════════════════════════════════
-- GESTION DES JOUEURS
-- ═══════════════════════════════════════════════════════════════

-- Ajouter un joueur à une instance
local function AddPlayerToInstance(playerId, instance)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    
    if not xPlayer then
        Config.ErrorPrint('Joueur introuvable: ' .. playerId)
        return false
    end
    
    -- Vérifier si le joueur est déjà en jeu
    if playersInGame[playerId] then
        Config.ErrorPrint('Le joueur ' .. playerId .. ' est déjà en jeu')
        return false
    end
    
    -- Ajouter le joueur à l'instance
    table.insert(instance.players, playerId)
    
    -- Sauvegarder les données du joueur
    playersInGame[playerId] = {
        instanceId = instance.id,
        bucket = instance.bucket,
        originalBucket = GetPlayerRoutingBucket(playerId),
        joinedAt = os.time()
    }
    
    -- Changer le routing bucket du joueur
    SetPlayerRoutingBucket(playerId, instance.bucket)
    
    Config.SuccessPrint('Joueur ' .. xPlayer.getName() .. ' ajouté à l\'instance ' .. instance.id)
    
    if Config.CoursePoursuit.LogEvents then
        print(string.format('[SCHARMAN] Joueur %s [%d] rejoint instance %s (bucket %d)', 
            xPlayer.getName(), playerId, instance.id, instance.bucket))
    end
    
    -- Notifier le joueur
    TriggerClientEvent('scharman:client:startCoursePoursuit', playerId, {
        instanceId = instance.id,
        spawnCoords = Config.CoursePoursuit.SpawnCoords,
        vehicleModel = instance.vehicleModel,
        spawnBot = (#instance.players == 1 and Config.CoursePoursuit.SpawnBotInSolo) -- Spawner bot si seul
    })
    
    -- Notifier les autres joueurs de l'instance
    local notification = string.format(Config.CoursePoursuit.Notifications.playerJoined, xPlayer.getName())
    for _, pid in ipairs(instance.players) do
        if pid ~= playerId then
            TriggerClientEvent('scharman:client:courseNotification', pid, notification, 3000)
        end
    end
    
    return true
end

-- Retirer un joueur d'une instance
function RemovePlayerFromInstance(playerId, instanceId)
    local playerData = playersInGame[playerId]
    
    if not playerData then
        Config.ErrorPrint('Joueur ' .. playerId .. ' n\'est pas en jeu')
        return false
    end
    
    local instance = activeInstances[instanceId or playerData.instanceId]
    
    if not instance then
        Config.ErrorPrint('Instance introuvable')
        return false
    end
    
    local xPlayer = ESX.GetPlayerFromId(playerId)
    local playerName = xPlayer and xPlayer.getName() or 'Inconnu'
    
    -- Retirer le joueur de l'instance
    for i, pid in ipairs(instance.players) do
        if pid == playerId then
            table.remove(instance.players, i)
            break
        end
    end
    
    -- Remettre le joueur dans le bucket original
    SetPlayerRoutingBucket(playerId, playerData.originalBucket or 0)
    
    -- Nettoyer les données
    playersInGame[playerId] = nil
    
    Config.SuccessPrint('Joueur ' .. playerName .. ' retiré de l\'instance ' .. instance.id)
    
    if Config.CoursePoursuit.LogEvents then
        print(string.format('[SCHARMAN] Joueur %s [%d] a quitté instance %s', 
            playerName, playerId, instance.id))
    end
    
    -- Notifier le joueur
    TriggerClientEvent('scharman:client:stopCoursePoursuit', playerId)
    
    -- Notifier les autres joueurs
    local notification = string.format(Config.CoursePoursuit.Notifications.playerLeft, playerName)
    for _, pid in ipairs(instance.players) do
        TriggerClientEvent('scharman:client:courseNotification', pid, notification, 3000)
    end
    
    -- Supprimer l'instance si vide
    if #instance.players == 0 then
        Config.InfoPrint('Instance vide, suppression...')
        DeleteInstance(instance.id)
    end
    
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- ÉVÉNEMENTS
-- ═══════════════════════════════════════════════════════════════

-- Événement: Joueur veut rejoindre le jeu
RegisterNetEvent('scharman:server:joinCoursePoursuit', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        Config.ErrorPrint('Joueur introuvable: ' .. source)
        return
    end
    
    Config.InfoPrint(xPlayer.getName() .. ' veut rejoindre Course Poursuite')
    
    -- Vérifier si le mode est activé
    if not Config.CoursePoursuit.Enabled then
        TriggerClientEvent('scharman:client:courseNotification', source, '❌ Le mode Course Poursuite est désactivé', 3000)
        Config.ErrorPrint('Mode Course Poursuite désactivé')
        return
    end
    
    -- Mode solo : lancer directement sans chercher d'instance
    if Config.CoursePoursuit.AllowSolo then
        Config.InfoPrint(xPlayer.getName() .. ' lance en mode SOLO')
        
        -- Créer une instance solo
        local soloInstance = CreateInstance()
        
        if not soloInstance then
            TriggerClientEvent('scharman:client:courseNotification', source, '❌ Impossible de créer une instance', 3000)
            Config.ErrorPrint('Échec de la création d\'instance solo')
            return
        end
        
        -- Ajouter le joueur
        if AddPlayerToInstance(source, soloInstance) then
            Config.SuccessPrint(xPlayer.getName() .. ' a lancé le mode solo')
            
            -- Informer le client de spawner un bot
            -- Le client recevra spawnBot=true dans les données
        else
            TriggerClientEvent('scharman:client:courseNotification', source, '❌ Erreur lors de la connexion', 3000)
            Config.ErrorPrint('Échec de l\'ajout du joueur à l\'instance solo')
        end
        
        return
    end
    
    -- Mode multijoueur : trouver ou créer une instance
    
    -- Trouver ou créer une instance
    local instance = FindOrCreateInstance()
    
    if not instance then
        TriggerClientEvent('scharman:client:courseNotification', source, '❌ Impossible de créer une instance', 3000)
        Config.ErrorPrint('Échec de la création d\'instance')
        return
    end
    
    -- Vérifier si l'instance est pleine
    if #instance.players >= instance.maxPlayers then
        TriggerClientEvent('scharman:client:courseNotification', source, Config.CoursePoursuit.Notifications.instanceFull, 3000)
        Config.ErrorPrint('Instance pleine')
        return
    end
    
    -- Ajouter le joueur
    if AddPlayerToInstance(source, instance) then
        Config.SuccessPrint(xPlayer.getName() .. ' a rejoint le jeu')
    else
        TriggerClientEvent('scharman:client:courseNotification', source, '❌ Erreur lors de la connexion', 3000)
        Config.ErrorPrint('Échec de l\'ajout du joueur à l\'instance')
    end
end)

-- Événement: Joueur quitte le jeu
RegisterNetEvent('scharman:server:coursePoursuiteLeft', function()
    local source = source
    local playerData = playersInGame[source]
    
    if not playerData then
        return
    end
    
    RemovePlayerFromInstance(source, playerData.instanceId)
end)

-- ═══════════════════════════════════════════════════════════════
-- GESTION DE LA DÉCONNEXION
-- ═══════════════════════════════════════════════════════════════

AddEventHandler('playerDropped', function(reason)
    local source = source
    local playerData = playersInGame[source]
    
    if playerData then
        Config.InfoPrint('Joueur ' .. source .. ' déconnecté pendant le jeu')
        RemovePlayerFromInstance(source, playerData.instanceId)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- COMMANDES ADMIN
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('course_instances', function(source, args, rawCommand)
    if source > 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or xPlayer.getGroup() ~= 'admin' then
            return
        end
    end
    
    print('═══════════════════════════════════════════════════════════════')
    print('Instances Course Poursuite actives:')
    print('═══════════════════════════════════════════════════════════════')
    
    local count = 0
    for instanceId, instance in pairs(activeInstances) do
        count = count + 1
        print(string.format('%d. Instance: %s (Bucket: %d)', count, instanceId, instance.bucket))
        print(string.format('   Joueurs: %d/%d', #instance.players, instance.maxPlayers))
        print(string.format('   Véhicule: %s', instance.vehicleModel))
        print(string.format('   Créée: %s', os.date('%H:%M:%S', instance.createdAt)))
        
        for i, playerId in ipairs(instance.players) do
            local xPlayer = ESX.GetPlayerFromId(playerId)
            local name = xPlayer and xPlayer.getName() or 'Inconnu'
            print(string.format('      %d. %s [ID: %d]', i, name, playerId))
        end
    end
    
    if count == 0 then
        print('Aucune instance active')
    end
    
    print('═══════════════════════════════════════════════════════════════')
    print('Total: ' .. count .. ' instance(s)')
    print('═══════════════════════════════════════════════════════════════')
end, true)

RegisterCommand('course_kick', function(source, args, rawCommand)
    if source > 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or xPlayer.getGroup() ~= 'admin' then
            return
        end
    end
    
    local targetId = tonumber(args[1])
    
    if not targetId then
        print('Usage: /course_kick [player_id]')
        return
    end
    
    if playersInGame[targetId] then
        RemovePlayerFromInstance(targetId)
        print('Joueur ' .. targetId .. ' éjecté de Course Poursuite')
    else
        print('Le joueur ' .. targetId .. ' n\'est pas en jeu')
    end
end, true)

-- ═══════════════════════════════════════════════════════════════
-- NETTOYAGE
-- ═══════════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Config.InfoPrint('Arrêt du mode Course Poursuite, nettoyage...')
    
    -- Retirer tous les joueurs et supprimer les instances
    for instanceId, instance in pairs(activeInstances) do
        DeleteInstance(instanceId)
    end
    
    Config.SuccessPrint('Nettoyage terminé')
end)

Config.DebugPrint('Fichier server/course_poursuite.lua chargé avec succès')
