-- SERVER - MODE COURSE POURSUITE (ROUTING BUCKETS)
ESX = exports['es_extended']:getSharedObject()

local activeInstances = {}
local playersInGame = {}
local lastUsedBucket = Config.CoursePoursuit.BucketRange.min - 1

local function GetNextAvailableBucket()
    lastUsedBucket = lastUsedBucket + 1
    if lastUsedBucket > Config.CoursePoursuit.BucketRange.max then
        lastUsedBucket = Config.CoursePoursuit.BucketRange.min
    end
    for instanceId, instance in pairs(activeInstances) do
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

local function CreateInstance()
    local instanceCount = 0
    for _ in pairs(activeInstances) do instanceCount = instanceCount + 1 end
    if instanceCount >= Config.CoursePoursuit.MaxInstances then
        Config.ErrorPrint('Nombre maximum d\'instances atteint')
        return nil
    end
    
    local instanceId = GenerateInstanceId()
    local bucket = GetNextAvailableBucket()
    
    local instance = {
        id = instanceId,
        bucket = bucket,
        players = {},
        createdAt = os.time(),
        maxPlayers = Config.CoursePoursuit.MaxPlayersPerInstance,
        vehicleModel = GetVehicleModel()
    }
    
    SetRoutingBucketPopulationEnabled(bucket, false)
    SetRoutingBucketEntityLockdownMode(bucket, Config.CoursePoursuit.BucketLockdown)
    activeInstances[instanceId] = instance
    Config.SuccessPrint('Instance créée: ' .. instanceId .. ' (Bucket: ' .. bucket .. ')')
    return instance
end

local function DeleteInstance(instanceId)
    local instance = activeInstances[instanceId]
    if not instance then return false end
    for _, playerId in ipairs(instance.players) do
        RemovePlayerFromInstance(playerId, instanceId)
    end
    activeInstances[instanceId] = nil
    Config.SuccessPrint('Instance supprimée: ' .. instanceId)
    return true
end

local function FindOrCreateInstance()
    for instanceId, instance in pairs(activeInstances) do
        if #instance.players < instance.maxPlayers then
            return instance
        end
    end
    return CreateInstance()
end

local function AddPlayerToInstance(playerId, instance)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    if playersInGame[playerId] then return false end
    
    table.insert(instance.players, playerId)
    playersInGame[playerId] = {
        instanceId = instance.id,
        bucket = instance.bucket,
        originalBucket = GetPlayerRoutingBucket(playerId),
        joinedAt = os.time()
    }
    
    SetPlayerRoutingBucket(playerId, instance.bucket)
    Wait(1000)
    
    local success, vehicleNetId = pcall(function()
        local spawnCoords = Config.CoursePoursuit.SpawnCoords
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
        
        Config.SuccessPrint('[SERVER] Véhicule créé: ' .. vehicle .. ' NetID: ' .. netId)
        return netId
    end)
    
    if not success then
        Config.ErrorPrint('[SERVER] Erreur véhicule: ' .. tostring(vehicleNetId))
        for i, pid in ipairs(instance.players) do
            if pid == playerId then table.remove(instance.players, i) break end
        end
        playersInGame[playerId] = nil
        SetPlayerRoutingBucket(playerId, 0)
        TriggerClientEvent('scharman:client:courseNotification', playerId, '❌ Erreur création véhicule', 5000, 'error')
        return false
    end
    
    TriggerClientEvent('scharman:client:startCoursePoursuit', playerId, {
        instanceId = instance.id,
        spawnCoords = Config.CoursePoursuit.SpawnCoords,
        vehicleModel = instance.vehicleModel,
        spawnBot = (#instance.players == 1 and Config.CoursePoursuit.SpawnBotInSolo),
        bucketId = instance.bucket,
        vehicleNetId = vehicleNetId
    })
    
    local notification = string.format(Config.CoursePoursuit.Notifications.playerJoined, xPlayer.getName())
    for _, pid in ipairs(instance.players) do
        if pid ~= playerId then
            TriggerClientEvent('scharman:client:courseNotification', pid, notification, 3000)
        end
    end
    
    return true
end

function RemovePlayerFromInstance(playerId, instanceId)
    local playerData = playersInGame[playerId]
    if not playerData then return false end
    
    local instance = activeInstances[instanceId or playerData.instanceId]
    if not instance then return false end
    
    local xPlayer = ESX.GetPlayerFromId(playerId)
    local playerName = xPlayer and xPlayer.getName() or 'Inconnu'
    
    for i, pid in ipairs(instance.players) do
        if pid == playerId then table.remove(instance.players, i) break end
    end
    
    SetPlayerRoutingBucket(playerId, playerData.originalBucket or 0)
    playersInGame[playerId] = nil
    
    TriggerClientEvent('scharman:client:stopCoursePoursuit', playerId)
    
    local notification = string.format(Config.CoursePoursuit.Notifications.playerLeft, playerName)
    for _, pid in ipairs(instance.players) do
        TriggerClientEvent('scharman:client:courseNotification', pid, notification, 3000)
    end
    
    if #instance.players == 0 then
        DeleteInstance(instance.id)
    end
    
    return true
end

RegisterNetEvent('scharman:server:joinCoursePoursuit', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    if not Config.CoursePoursuit.Enabled then
        TriggerClientEvent('scharman:client:courseNotification', source, '❌ Mode désactivé', 3000)
        return
    end
    
    if Config.CoursePoursuit.AllowSolo then
        local soloInstance = CreateInstance()
        if not soloInstance then
            TriggerClientEvent('scharman:client:courseNotification', source, '❌ Impossible de créer une instance', 3000)
            return
        end
        AddPlayerToInstance(source, soloInstance)
        return
    end
    
    local instance = FindOrCreateInstance()
    if not instance then
        TriggerClientEvent('scharman:client:courseNotification', source, '❌ Impossible de créer une instance', 3000)
        return
    end
    
    if #instance.players >= instance.maxPlayers then
        TriggerClientEvent('scharman:client:courseNotification', source, Config.CoursePoursuit.Notifications.instanceFull, 3000)
        return
    end
    
    AddPlayerToInstance(source, instance)
end)

RegisterNetEvent('scharman:server:coursePoursuiteLeft', function()
    local source = source
    local playerData = playersInGame[source]
    if not playerData then return end
    RemovePlayerFromInstance(source, playerData.instanceId)
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    local playerData = playersInGame[source]
    if playerData then
        RemovePlayerFromInstance(source, playerData.instanceId)
    end
end)

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
        print(string.format('   Joueurs: %d/%d', #instance.players, instance.maxPlayers))
        print(string.format('   Véhicule: %s', instance.vehicleModel))
        for i, playerId in ipairs(instance.players) do
            local xPlayer = ESX.GetPlayerFromId(playerId)
            local name = xPlayer and xPlayer.getName() or 'Inconnu'
            print(string.format('      %d. %s [ID: %d]', i, name, playerId))
        end
    end
    if count == 0 then print('Aucune instance active') end
    print('Total: ' .. count .. ' instance(s)')
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

Config.DebugPrint('server/course_poursuite.lua chargé')
