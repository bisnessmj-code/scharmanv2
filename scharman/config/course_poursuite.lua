Config.CoursePoursuit = {}

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION GÉNÉRALE
-- ═══════════════════════════════════════════════════════════════

Config.CoursePoursuit.Enabled = true
Config.CoursePoursuit.MaxPlayersPerInstance = 2 -- 1v1 uniquement
Config.CoursePoursuit.MaxInstances = 25
Config.CoursePoursuit.GameDuration = 300 -- 5 minutes (0 = infini)

-- ═══════════════════════════════════════════════════════════════
-- POSITIONS (⚠️ À MODIFIER)
-- ═══════════════════════════════════════════════════════════════

-- Position spawn joueur 1
Config.CoursePoursuit.SpawnCoords = {
    player1 = vector4(-2124.83, -301.81, 13.09, 73.70), -- ⚠️ CHANGE-MOI!
    player2 = vector4(-2134.83, -311.81, 13.09, 73.70)  -- ⚠️ CHANGE-MOI!
}

-- Position de retour après partie
Config.CoursePoursuit.ReturnToNormalCoords = vector4(-2148.92, -330.63, 12.99, 141.73) -- ⚠️ CHANGE-MOI!

-- ═══════════════════════════════════════════════════════════════
-- VÉHICULES
-- ═══════════════════════════════════════════════════════════════

Config.CoursePoursuit.VehicleModel = 'sultan'
Config.CoursePoursuit.VehicleList = {
    'sultan', 'futo', 'elegy2', 'jester', 'massacro'
}
Config.CoursePoursuit.RandomVehicle = false

-- Personnalisation véhicules
Config.CoursePoursuit.VehicleCustomization = {
    player1 = {
        primaryColor = {r = 255, g = 0, b = 0},   -- Rouge
        secondaryColor = {r = 0, g = 0, b = 0},   -- Noir
        plate = 'PLAYER1'
    },
    player2 = {
        primaryColor = {r = 0, g = 100, b = 255}, -- Bleu
        secondaryColor = {r = 0, g = 0, b = 0},   -- Noir
        plate = 'PLAYER2'
    },
    mods = {
        engine = 3,
        brakes = 2,
        transmission = 2,
        suspension = 1,
        turbo = true
    }
}

-- ═══════════════════════════════════════════════════════════════
-- DÉCOMPTE & BLOCAGE VÉHICULE
-- ═══════════════════════════════════════════════════════════════

Config.CoursePoursuit.EnableCountdown = true
Config.CoursePoursuit.BlockExitVehicle = true
Config.CoursePoursuit.BlockExitDuration = 30 -- secondes

-- ═══════════════════════════════════════════════════════════════
-- ZONE DE GUERRE (PVP)
-- ═══════════════════════════════════════════════════════════════

Config.CoursePoursuit.EnableWarZone = true
Config.CoursePoursuit.WarZoneRadius = 50.0 -- mètres
Config.CoursePoursuit.WarZoneLightHeight = 150.0
Config.CoursePoursuit.WarZoneBlipSprite = 84 -- Crâne
Config.CoursePoursuit.WarZoneBlipColor = 1  -- Rouge

-- Dégâts hors zone
Config.CoursePoursuit.OutOfZoneDamage = 20    -- HP par seconde
Config.CoursePoursuit.DamageInterval = 1000    -- ms entre chaque dégât

-- Couleur de la zone
Config.CoursePoursuit.WarZoneColor = {
    r = 255, g = 0, b = 0, a = 100
}

-- ═══════════════════════════════════════════════════════════════
-- ARMES
-- ═══════════════════════════════════════════════════════════════

Config.CoursePoursuit.WeaponHash = 'WEAPON_PISTOL50' -- Cal .50
Config.CoursePoursuit.WeaponAmmo = 250

-- ═══════════════════════════════════════════════════════════════
-- ROUTING BUCKETS
-- ═══════════════════════════════════════════════════════════════

Config.CoursePoursuit.BucketRange = {
    min = 1000,
    max = 2000
}
Config.CoursePoursuit.BucketLockdown = 'strict'

-- ═══════════════════════════════════════════════════════════════
-- MESSAGES & NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════════

Config.CoursePoursuit.Notifications = {
    -- Recherche de joueur
    searching = "🔍 Recherche d'un adversaire...",
    playerFound = "✅ Adversaire trouvé ! Préparation...",
    
    -- Démarrage
    teleporting = "🚀 Téléportation en cours...",
    starting = "🏁 La partie commence dans 3 secondes...",
    started = "🏁 C'est parti ! Éliminez votre adversaire !",
    
    -- Zone de guerre
    vehicleLocked = "🔒 Véhicule verrouillé pendant 30 secondes",
    canExitVehicle = "✅ Vous pouvez maintenant sortir du véhicule!",
    warZoneCreated = "🔴 ZONE DE GUERRE créée à votre position !",
    weaponGiven = "🔫 Pistolet Cal .50 équipé !",
    
    -- Adversaire
    opponentCreatedZone = "⚠️ Votre adversaire a créé la zone de guerre !",
    opponentInZone = "✅ Votre adversaire a rejoint la zone ! Vous pouvez descendre !",
    waitingOpponent = "⏳ Attendez que votre adversaire rejoigne la zone...",
    
    -- Dégâts
    outOfZone = "⚠️ HORS ZONE! Revenez ou vous allez mourir!",
    takingDamage = "⚡ DÉGÂTS ZONE: -%d HP",
    
    -- Fin de partie
    playerJoined = "✅ %s a rejoint la partie",
    playerLeft = "❌ %s a quitté la partie",
    youWon = "🏆 VICTOIRE ! Vous avez gagné !",
    youLost = "💀 DÉFAITE ! Vous êtes mort !",
    ended = "🏁 La partie est terminée !",
    
    -- Erreurs
    instanceFull = "❌ Cette instance est pleine",
    noPlayerFound = "❌ Aucun joueur trouvé. Réessayez.",
    errorCreatingInstance = "❌ Impossible de créer une instance"
}

Config.CoursePoursuit.MessageDuration = 3000

-- ═══════════════════════════════════════════════════════════════
-- BOT (MODE TEST UNIQUEMENT)
-- ═══════════════════════════════════════════════════════════════

Config.CoursePoursuit.Bot = {
    enabled = false, -- Désactivé par défaut
    model = 'a_m_y_runner_01',
    vehicle = 'futo',
    vehicleColor = {
        primary = {r = 255, g = 0, b = 0},
        secondary = {r = 0, g = 0, b = 0}
    },
    spawnOffset = vector3(10.0, 10.0, 0.0),
    drivingStyle = 786603,
    speed = 30.0,
    randomRoute = true
}

-- ═══════════════════════════════════════════════════════════════
-- DEBUG
-- ═══════════════════════════════════════════════════════════════

Config.CoursePoursuit.DebugMode = true
Config.CoursePoursuit.LogEvents = true
