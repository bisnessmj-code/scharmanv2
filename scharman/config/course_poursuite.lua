Config.CoursePoursuit = {}

-- Activer/Désactiver le mode
Config.CoursePoursuit.Enabled = true

-- Mode solo (lancer même si seul)
Config.CoursePoursuit.AllowSolo = true

-- Spawner un bot IA en mode solo
Config.CoursePoursuit.SpawnBotInSolo = true

-- Nombre de bots à spawner en mode solo
Config.CoursePoursuit.BotsInSolo = 1

-- Nombre maximum de joueurs par instance
Config.CoursePoursuit.MaxPlayersPerInstance = 4

-- Nombre maximum d'instances simultanées
Config.CoursePoursuit.MaxInstances = 25

-- Durée d'une partie (en secondes, 0 = infini)
Config.CoursePoursuit.GameDuration = 300 -- 5 minutes

-- ⚠️ À MODIFIER: Point de spawn du joueur (coordonnées + heading)
Config.CoursePoursuit.SpawnCoords = vector4(-2124.83, -301.81, 13.09, 73.70) -- ⚠️ CHANGE-MOI!

-- Modèle de véhicule à spawn
Config.CoursePoursuit.VehicleModel = 'sultan'

-- Liste de véhicules possibles (choix aléatoire)
Config.CoursePoursuit.VehicleList = {
    'sultan',
    'futo',
    'elegy2',
    'jester',
    'massacro'
}

-- Utiliser une voiture aléatoire ?
Config.CoursePoursuit.RandomVehicle = false

-- Personnalisation du véhicule
Config.CoursePoursuit.VehicleCustomization = {
    primaryColor = {r = 255, g = 0, b = 0}, -- Rouge
    secondaryColor = {r = 0, g = 0, b = 0}, -- Noir
    plate = 'SCHARMAN',
    mods = {
        engine = 3,
        brakes = 2,
        transmission = 2,
        suspension = 1,
        armor = 0,
        turbo = true
    }
}

-- Activer le décompte 3-2-1-GO au spawn
Config.CoursePoursuit.EnableCountdown = true

-- Empêcher le joueur de sortir du véhicule pendant X secondes
Config.CoursePoursuit.BlockExitVehicle = true

-- Durée du blocage de sortie (en secondes)
Config.CoursePoursuit.BlockExitDuration = 30

-- Message si le joueur tente de sortir
Config.CoursePoursuit.BlockExitMessage = "Vous ne pouvez pas sortir du véhicule pour l'instant !"

-- Durée d'affichage du message (en ms)
Config.CoursePoursuit.MessageDuration = 3000

-- Désactiver les armes dans le véhicule
Config.CoursePoursuit.DisableWeapons = true

-- Activer la zone de guerre automatique au spawn
Config.CoursePoursuit.EnableWarZone = true

-- Rayon de la zone de guerre (en mètres)
Config.CoursePoursuit.WarZoneRadius = 50.0

-- Couleur de la zone de guerre (RGB + Alpha)
Config.CoursePoursuit.WarZoneColor = {
    r = 255,
    g = 0,
    b = 0,
    a = 100
}

-- Hauteur de la colonne de lumière (en mètres)
Config.CoursePoursuit.WarZoneLightHeight = 150.0

-- Type de blip pour le centre de la zone
Config.CoursePoursuit.WarZoneBlipSprite = 84 -- Crâne

-- Couleur du blip (1 = Rouge)
Config.CoursePoursuit.WarZoneBlipColor = 1

-- Range de routing buckets à utiliser (de 1000 à 2000)
Config.CoursePoursuit.BucketRange = {
    min = 1000,
    max = 2000
}

-- Lockdown mode du routing bucket
Config.CoursePoursuit.BucketLockdown = 'strict'

-- Notifications
Config.CoursePoursuit.Notifications = {
    starting = "🏁 La course commence dans 3 secondes...",
    started = "🏁 C'est parti ! Bonne chance !",
    ended = "🏁 La partie est terminée !",
    playerJoined = "✅ %s a rejoint la partie",
    playerLeft = "❌ %s a quitté la partie",
    instanceFull = "❌ Cette instance est pleine",
    teleporting = "🚀 Téléportation en cours...",
    countdownStart = "⏱️ Préparez-vous...",
    vehicleLocked = "🔒 Véhicule verrouillé pendant 30 secondes",
    warZoneCreated = "🔴 ZONE DE GUERRE créée !"
}

-- ⚠️ À MODIFIER: Position de retour après la partie (position du PED)
Config.CoursePoursuit.ReturnToNormalCoords = vector4(-2148.92, -330.63, 12.99, 141.73) -- ⚠️ CHANGE-MOI!

-- Temps avant retour automatique (en secondes, 0 = désactivé)
Config.CoursePoursuit.AutoReturnTime = 0

-- Message de fin de partie
Config.CoursePoursuit.EndGameMessage = "Merci d'avoir joué ! Retour à la normale..."

-- Activer la limitation de zone
Config.CoursePoursuit.UseZoneLimit = false

-- Centre de la zone
Config.CoursePoursuit.ZoneCenter = vector3(-2124.83, -301.81, 13.09)

-- Rayon de la zone (en mètres)
Config.CoursePoursuit.ZoneRadius = 500.0

-- Message si le joueur sort de la zone
Config.CoursePoursuit.OutOfZoneMessage = "⚠️ Retournez dans la zone de jeu !"

-- Temps avant téléportation forcée (en secondes)
Config.CoursePoursuit.OutOfZoneTimeout = 10

-- Afficher les informations de debug
Config.CoursePoursuit.DebugMode = true

-- Logger les événements
Config.CoursePoursuit.LogEvents = true

-- Modèle du bot
Config.CoursePoursuit.BotModel = 'a_m_y_runner_01'

-- Véhicule du bot
Config.CoursePoursuit.BotVehicle = 'futo'

-- Couleur du véhicule bot
Config.CoursePoursuit.BotVehicleColor = {
    primary = {r = 255, g = 0, b = 0},    -- Rouge
    secondary = {r = 0, g = 0, b = 0}     -- Noir
}

-- Position de spawn du bot (offset depuis le joueur)
Config.CoursePoursuit.BotSpawnOffset = vector3(10.0, 10.0, 0.0)

-- Style de conduite du bot (786603 = Normal)
Config.CoursePoursuit.BotDrivingStyle = 786603

-- Vitesse du bot
Config.CoursePoursuit.BotSpeed = 30.0

-- Le bot suit une route aléatoire
Config.CoursePoursuit.BotRandomRoute = true
