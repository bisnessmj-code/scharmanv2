-- ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
-- ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
-- ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
-- ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
-- ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
-- CLIENT NUI - Gestion de l'interface utilisateur
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- VARIABLES LOCALES
-- ═══════════════════════════════════════════════════════════════

-- État de l'interface
local isNuiOpen = false

-- Thread de désactivation des contrôles
local disableControlsThread = nil

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Jouer un son
-- ═══════════════════════════════════════════════════════════════

local function PlayUISound(soundConfig)
    if soundConfig.enabled then
        PlaySoundFrontend(-1, soundConfig.name, soundConfig.set, true)
        Config.DebugPrint('Son joué: ' .. soundConfig.name)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Activer/Désactiver le flou d'écran
-- ═══════════════════════════════════════════════════════════════

local function SetBlurState(state)
    if not Config.NUI.enableBlur then return end
    
    if state then
        TriggerScreenblurFadeIn(300)
        Config.DebugPrint('Flou d\'écran activé')
    else
        TriggerScreenblurFadeOut(300)
        Config.DebugPrint('Flou d\'écran désactivé')
    end
end

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Désactiver les contrôles du joueur
-- ═══════════════════════════════════════════════════════════════

local function StartDisableControls()
    if not Config.NUI.disableControls then return end
    
    if disableControlsThread then return end
    
    Config.DebugPrint('Désactivation des contrôles démarrée')
    
    disableControlsThread = CreateThread(function()
        while isNuiOpen do
            -- Désactiver tous les contrôles configurés
            for _, control in ipairs(Config.NUI.disabledControls) do
                DisableControlAction(0, control, true)
            end
            
            -- Désactiver les attaques au corps à corps
            DisablePlayerFiring(PlayerPedId(), true)
            
            Wait(0)
        end
        
        Config.DebugPrint('Désactivation des contrôles arrêtée')
        disableControlsThread = nil
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Arrêter la désactivation des contrôles
-- ═══════════════════════════════════════════════════════════════

local function StopDisableControls()
    if disableControlsThread then
        disableControlsThread = nil
        Config.DebugPrint('Thread de désactivation des contrôles arrêté')
    end
end

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Ouvrir l'interface NUI
-- ═══════════════════════════════════════════════════════════════

local function OpenNUI()
    -- Vérifier si l'interface est déjà ouverte
    if isNuiOpen then
        Config.DebugPrint('Interface déjà ouverte')
        return
    end
    
    -- Vérifier si le joueur est proche du PED
    if not IsPlayerNearPed() then
        ESX.ShowNotification(Config.Texts.tooFar, 'error')
        Config.DebugPrint('Joueur trop loin du PED')
        return
    end
    
    Config.DebugPrint('Ouverture de l\'interface NUI...')
    
    -- Jouer le son d'ouverture
    PlayUISound(Config.NUI.openSound)
    
    -- Activer le flou
    SetBlurState(true)
    
    -- Mettre à jour l'état
    isNuiOpen = true
    SetNuiState(true)
    
    -- Envoyer le message à l'interface HTML
    SendNUIMessage({
        action = 'open',
        data = {
            animationDuration = Config.NUI.openAnimationDuration
        }
    })
    
    -- Activer le focus NUI
    SetNuiFocus(true, true)
    Config.DebugPrint('Focus NUI activé')
    
    -- Désactiver les contrôles
    StartDisableControls()
    
    -- Notification serveur
    TriggerServerEvent('scharman:server:nuiOpened')
    
    Config.SuccessPrint(Config.Texts.nuiOpened)
end

-- ═══════════════════════════════════════════════════════════════
-- FONCTION: Fermer l'interface NUI
-- ═══════════════════════════════════════════════════════════════

local function CloseNUI()
    -- Vérifier si l'interface est ouverte
    if not isNuiOpen then
        Config.DebugPrint('Interface déjà fermée')
        return
    end
    
    Config.DebugPrint('Fermeture de l\'interface NUI...')
    
    -- Jouer le son de fermeture
    PlayUISound(Config.NUI.closeSound)
    
    -- Désactiver le flou
    SetBlurState(false)
    
    -- Mettre à jour l'état
    isNuiOpen = false
    SetNuiState(false)
    
    -- Envoyer le message à l'interface HTML
    SendNUIMessage({
        action = 'close',
        data = {
            animationDuration = Config.NUI.closeAnimationDuration
        }
    })
    
    -- Désactiver le focus NUI
    SetNuiFocus(false, false)
    Config.DebugPrint('Focus NUI désactivé')
    
    -- Réactiver les contrôles
    StopDisableControls()
    
    -- Notification serveur
    TriggerServerEvent('scharman:server:nuiClosed')
    
    Config.SuccessPrint(Config.Texts.nuiClosed)
end

-- ═══════════════════════════════════════════════════════════════
-- BOUCLE: Détecter la touche ÉCHAP pour fermer l'interface
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(0)
        
        if isNuiOpen then
            -- Détecter l'appui sur ÉCHAP
            if IsControlJustReleased(0, 322) then -- ESC
                Config.DebugPrint('Touche ÉCHAP détectée')
                CloseNUI()
            end
        else
            -- Si l'interface est fermée, attendre plus longtemps pour économiser les performances
            Wait(500)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- BOUCLE: Vérifier la distance avec le PED (fermeture auto)
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(Config.Performance.distanceCheckInterval)
        
        if isNuiOpen then
            -- Vérifier si le joueur est encore proche
            if not IsPlayerNearPed() then
                Config.DebugPrint('Joueur trop loin, fermeture automatique')
                ESX.ShowNotification(Config.Texts.interactionCancelled, 'warning')
                CloseNUI()
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- CALLBACK NUI: Messages depuis l'interface HTML
-- ═══════════════════════════════════════════════════════════════

-- Callback pour fermer l'interface depuis HTML
RegisterNUICallback('close', function(data, cb)
    Config.DebugPrint('Callback NUI: close reçu')
    CloseNUI()
    cb('ok')
end)

-- Callback pour tester la connexion
RegisterNUICallback('ping', function(data, cb)
    Config.DebugPrint('Callback NUI: ping reçu')
    cb({
        status = 'success',
        message = 'pong',
        timestamp = os.time()
    })
end)

-- Callback générique pour logger les actions
RegisterNUICallback('log', function(data, cb)
    if data.message then
        Config.DebugPrint('NUI Log: ' .. tostring(data.message))
    end
    cb('ok')
end)

-- ═══════════════════════════════════════════════════════════════
-- ÉVÉNEMENTS
-- ═══════════════════════════════════════════════════════════════

-- Événement pour ouvrir l'interface
RegisterNetEvent('scharman:client:nui:open', function()
    OpenNUI()
end)

-- Événement pour fermer l'interface
RegisterNetEvent('scharman:client:nui:close', function()
    CloseNUI()
end)

-- Événement pour toggle l'interface
RegisterNetEvent('scharman:client:nui:toggle', function()
    if isNuiOpen then
        CloseNUI()
    else
        OpenNUI()
    end
end)

-- Événement d'interaction (démarre l'interaction)
RegisterNetEvent('scharman:client:interaction:start', function()
    Config.DebugPrint('Système d\'interaction démarré')
end)

-- ═══════════════════════════════════════════════════════════════
-- COMMANDES DE DEBUG
-- ═══════════════════════════════════════════════════════════════

if Config.Debug then
    -- Commande pour ouvrir l'interface
    RegisterCommand('scharman_open', function()
        OpenNUI()
    end, false)
    
    -- Commande pour fermer l'interface
    RegisterCommand('scharman_close', function()
        CloseNUI()
    end, false)
    
    -- Commande pour toggle l'interface
    RegisterCommand('scharman_toggle', function()
        if isNuiOpen then
            CloseNUI()
        else
            OpenNUI()
        end
    end, false)
    
    Config.InfoPrint('Commandes de debug NUI disponibles:')
    Config.InfoPrint('- /scharman_open')
    Config.InfoPrint('- /scharman_close')
    Config.InfoPrint('- /scharman_toggle')
end

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('OpenUI', function()
    OpenNUI()
end)

exports('CloseUI', function()
    CloseNUI()
end)

exports('ToggleUI', function()
    if isNuiOpen then
        CloseNUI()
    else
        OpenNUI()
    end
end)

exports('IsUIOpen', function()
    return isNuiOpen
end)

Config.DebugPrint('Fichier client/nui.lua chargé avec succès')
