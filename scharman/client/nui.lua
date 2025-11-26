-- ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
-- ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
-- ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
-- ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
-- ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
-- CLIENT - NUI
-- ═══════════════════════════════════════════════════════════════

local isNuiOpen = false
local disableControlsThread = nil

-- ═══════════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES
-- ═══════════════════════════════════════════════════════════════

local function SetNuiState(state)
    isNuiOpen = state
end

local function PlayUISound(soundName)
    PlaySoundFrontend(-1, soundName, 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    Config.DebugPrint('Son joué: ' .. soundName)
end

local function SetBlurState(enable)
    if not Config.NUI.enableBlur then return end
    
    if enable then
        TriggerScreenblurFadeIn(Config.NUI.blurIntensity)
        Config.DebugPrint('Flou d\'écran activé')
    else
        TriggerScreenblurFadeOut(Config.NUI.blurIntensity)
        Config.DebugPrint('Flou d\'écran désactivé')
    end
end

-- ═══════════════════════════════════════════════════════════════
-- GESTION DES CONTRÔLES
-- ═══════════════════════════════════════════════════════════════

local function StartDisableControls()
    if disableControlsThread then return end
    
    Config.DebugPrint('Désactivation des contrôles démarrée')
    
    disableControlsThread = CreateThread(function()
        while isNuiOpen do
            Wait(0)
            
            for _, control in ipairs(Config.DisabledControls) do
                DisableControlAction(0, control, true)
            end
        end
        
        disableControlsThread = nil
        Config.DebugPrint('Désactivation des contrôles arrêtée')
    end)
end

local function StopDisableControls()
    disableControlsThread = nil
    Config.DebugPrint('Thread de désactivation des contrôles arrêté')
end

-- ═══════════════════════════════════════════════════════════════
-- OUVERTURE / FERMETURE NUI
-- ═══════════════════════════════════════════════════════════════

local function OpenNUI()
    if isNuiOpen then
        Config.DebugPrint('Interface déjà ouverte')
        return
    end
    
    Config.DebugPrint('Ouverture de l\'interface NUI...')
    
    -- Jouer le son
    PlayUISound(Config.NUI.openSound)
    
    -- Activer le flou
    SetBlurState(true)
    
    -- Mettre à jour l'état
    SetNuiState(true)
    
    -- Envoyer le message à l'interface
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
    
    Config.SuccessPrint(Config.Texts.nuiOpened)
end

local function CloseNUI()
    if not isNuiOpen then
        Config.DebugPrint('Interface déjà fermée')
        return
    end
    
    Config.DebugPrint('Fermeture de l\'interface NUI...')
    
    -- Jouer le son
    PlayUISound(Config.NUI.closeSound)
    
    -- Désactiver le flou
    SetBlurState(false)
    
    -- Mettre à jour l'état
    SetNuiState(false)
    
    -- Envoyer le message à l'interface
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
-- ÉVÉNEMENTS
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('scharman:client:openNUI', function()
    OpenNUI()
end)

RegisterNetEvent('scharman:client:closeNUI', function()
    CloseNUI()
end)

-- ═══════════════════════════════════════════════════════════════
-- CALLBACKS NUI
-- ═══════════════════════════════════════════════════════════════

-- Callback de fermeture
RegisterNUICallback('close', function(data, cb)
    Config.DebugPrint('Callback NUI: close reçu')
    CloseNUI()
    cb('ok')
end)

-- Callback pour rejoindre le mode Course Poursuite
RegisterNUICallback('joinCoursePoursuit', function(data, cb)
    Config.DebugPrint('Callback NUI: joinCoursePoursuit reçu')
    
    -- Fermer l'interface immédiatement
    CloseNUI()
    
    -- Envoyer la demande au serveur
    TriggerServerEvent('scharman:server:joinCoursePoursuit')
    
    -- Répondre au callback
    cb('ok')
end)

-- ═══════════════════════════════════════════════════════════════
-- COMMANDES DE DEBUG
-- ═══════════════════════════════════════════════════════════════

if Config.Debug then
    RegisterCommand('scharman_open', function()
        OpenNUI()
    end, false)
    
    RegisterCommand('scharman_close', function()
        CloseNUI()
    end, false)
    
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
-- GESTION ESC
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(0)
        
        if isNuiOpen then
            if IsControlJustReleased(0, 322) then -- ESC
                CloseNUI()
            end
        else
            Wait(500)
        end
    end
end)

Config.DebugPrint('Fichier client/nui.lua chargé avec succès')
