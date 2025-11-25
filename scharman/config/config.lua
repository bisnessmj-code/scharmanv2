-- ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
-- ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
-- ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
-- ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
-- ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
-- FICHIER DE CONFIGURATION - SCHARMAN PED
-- ═══════════════════════════════════════════════════════════════

Config = {}

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION GÉNÉRALE
-- ═══════════════════════════════════════════════════════════════

-- Active/Désactive le mode debug (logs dans la console F8)
Config.Debug = true

-- Nom du script (utilisé dans les logs)
Config.ScriptName = 'Scharman PED'

-- Version du script
Config.Version = '1.0.0'

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION DU PED
-- ═══════════════════════════════════════════════════════════════

Config.Ped = {
    -- Active/Désactive le spawn du PED
    enabled = true,
    
    -- Modèle du PED (liste complète: https://docs.fivem.net/docs/game-references/ped-models/)
    model = 'a_m_y_business_03', -- Homme en costume
    
    -- Position du PED (x, y, z, heading)
    coords = vector4(215.68, -810.12, 30.73, 250.0),
    
    -- Le PED est-il invincible ?
    invincible = true,
    
    -- Le PED est-il figé (ne bouge pas) ?
    frozen = true,
    
    -- Bloquer les événements (empêche le PED de réagir à l'environnement)
    blockEvents = true,
    
    -- Animation du PED (dictionnaire, animation, flag)
    -- Liste: https://alexguirre.github.io/animations-list/
    scenario = 'WORLD_HUMAN_CLIPBOARD', -- Le PED regarde un clipboard
    -- Pour utiliser une animation au lieu d'un scenario, décommentez:
    -- animation = {
    --     dict = 'anim@heists@prison_heiststation@cop_reactions',
    --     anim = 'cop_b_idle',
    --     flag = 49
    -- },
    
    -- Distance minimale pour voir le PED (optimisation)
    minRenderDistance = 50.0,
    
    -- Distance maximale d'interaction
    interactionDistance = 2.5,
}

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION DU BLIP
-- ═══════════════════════════════════════════════════════════════

Config.Blip = {
    -- Active/Désactive le blip sur la carte
    enabled = true,
    
    -- Sprite du blip (liste: https://docs.fivem.net/docs/game-references/blips/)
    sprite = 378, -- Icône tablette
    
    -- Couleur du blip (liste: https://docs.fivem.net/docs/game-references/blips/#blip-colors)
    color = 3, -- Bleu clair
    
    -- Échelle du blip (0.0 - 2.0)
    scale = 0.8,
    
    -- Le blip clignote-t-il ?
    isShortRange = true, -- Visible seulement quand on est proche
    
    -- Nom du blip
    label = 'Scharman - Mini Jeu',
}

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION DU MARQUEUR (3D TEXT / MARKER)
-- ═══════════════════════════════════════════════════════════════

Config.Marker = {
    -- Active/Désactive le marqueur 3D
    enabled = true,
    
    -- Type de marqueur (liste: https://docs.fivem.net/docs/game-references/markers/)
    -- 1 = Cylindre vertical
    -- 2 = Cylindre épais
    -- 27 = Cercle au sol
    type = 27,
    
    -- Taille du marqueur (x, y, z)
    size = vector3(1.0, 1.0, 0.5),
    
    -- Couleur RGBA (Rouge, Vert, Bleu, Alpha/Transparence)
    color = {r = 0, g = 150, b = 255, a = 200}, -- Bleu transparent
    
    -- Distance d'affichage du marqueur
    drawDistance = 10.0,
    
    -- Rotation du marqueur
    rotate = true,
    
    -- Texte d'aide (affiché en haut de l'écran)
    helpText = '~INPUT_CONTEXT~ Parler à ~b~Scharman~s~',
}

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION DE L'INTERFACE (NUI)
-- ═══════════════════════════════════════════════════════════════

Config.NUI = {
    -- Touche pour fermer l'interface (Code: https://docs.fivem.net/docs/game-references/controls/)
    closeKey = 'ESCAPE', -- Touche Échap
    
    -- Durée de l'animation d'ouverture (en millisecondes)
    openAnimationDuration = 500,
    
    -- Durée de l'animation de fermeture (en millisecondes)
    closeAnimationDuration = 400,
    
    -- Désactive les contrôles du joueur quand l'interface est ouverte
    disableControls = true,
    
    -- Active le flou d'arrière-plan
    enableBlur = true,
    
    -- Liste des contrôles à désactiver (si disableControls = true)
    -- Liste: https://docs.fivem.net/docs/game-references/controls/
    disabledControls = {
        0,  -- INPUT_NEXT_CAMERA
        1,  -- INPUT_LOOK_LR
        2,  -- INPUT_LOOK_UD
        24, -- INPUT_ATTACK
        25, -- INPUT_AIM
        140, -- INPUT_MELEE_ATTACK_LIGHT
        141, -- INPUT_MELEE_ATTACK_HEAVY
        142, -- INPUT_MELEE_ATTACK_ALTERNATE
        257, -- INPUT_ATTACK2
        263, -- INPUT_MELEE_ATTACK1
        264, -- INPUT_MELEE_ATTACK2
    },
    
    -- Son à jouer lors de l'ouverture (nom, volume)
    openSound = {
        enabled = true,
        name = 'SELECT',
        set = 'HUD_FRONTEND_DEFAULT_SOUNDSET'
    },
    
    -- Son à jouer lors de la fermeture
    closeSound = {
        enabled = true,
        name = 'BACK',
        set = 'HUD_FRONTEND_DEFAULT_SOUNDSET'
    },
}

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION DES TEXTES (Localisation future)
-- ═══════════════════════════════════════════════════════════════

Config.Texts = {
    pedSpawned = 'PED Scharman spawné avec succès',
    pedDeleted = 'PED Scharman supprimé',
    blipCreated = 'Blip Scharman créé',
    nuiOpened = 'Interface Scharman ouverte',
    nuiClosed = 'Interface Scharman fermée',
    tooFar = 'Vous êtes trop loin du PED',
    interactionCancelled = 'Interaction annulée',
}

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION AVANCÉE (Performance)
-- ═══════════════════════════════════════════════════════════════

Config.Performance = {
    -- Fréquence de vérification de la distance (en millisecondes)
    -- Plus la valeur est élevée, moins ça consomme (mais moins réactif)
    distanceCheckInterval = 500,
    
    -- Utilise les threads natifs (recommandé pour de meilleures performances)
    useNativeThreads = true,
    
    -- Active l'optimisation de la boucle de rendu
    optimizeRenderLoop = true,
}

-- ═══════════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES (NE PAS MODIFIER)
-- ═══════════════════════════════════════════════════════════════

-- Fonction pour afficher les logs de debug
function Config.DebugPrint(message)
    if Config.Debug then
        print(('[^3%s^7] ^5[DEBUG]^7 %s'):format(Config.ScriptName, message))
    end
end

-- Fonction pour afficher les erreurs
function Config.ErrorPrint(message)
    print(('[^3%s^7] ^1[ERROR]^7 %s'):format(Config.ScriptName, message))
end

-- Fonction pour afficher les succès
function Config.SuccessPrint(message)
    print(('[^3%s^7] ^2[SUCCESS]^7 %s'):format(Config.ScriptName, message))
end

-- Fonction pour afficher les infos
function Config.InfoPrint(message)
    print(('[^3%s^7] ^6[INFO]^7 %s'):format(Config.ScriptName, message))
end
