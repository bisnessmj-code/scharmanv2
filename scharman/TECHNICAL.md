# 🔧 Documentation Technique - SCHARMAN V2.0

## 📚 Table des Matières

1. [Architecture Générale](#architecture-générale)
2. [Flux de Données](#flux-de-données)
3. [Système de Décompte](#système-de-décompte)
4. [Système de Blocage Véhicule](#système-de-blocage-véhicule)
5. [Système de Zone de Guerre](#système-de-zone-de-guerre)
6. [Gestion des Threads](#gestion-des-threads)
7. [Nettoyage et Optimisation](#nettoyage-et-optimisation)
8. [API NUI](#api-nui)
9. [Bonnes Pratiques](#bonnes-pratiques)

---

## 🏗️ Architecture Générale

### Séparation des Responsabilités

```
┌─────────────────────────────────────────────────────┐
│                    CLIENT SIDE                       │
├─────────────────────────────────────────────────────┤
│  main.lua         │ Initialisation globale           │
│  ped.lua          │ Gestion PED + Interaction        │
│  nui.lua          │ Communication NUI                │
│  course_poursuite │ Logique du jeu                   │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                    SERVER SIDE                       │
├─────────────────────────────────────────────────────┤
│  main.lua         │ Initialisation serveur           │
│  version.lua      │ Vérification dépendances         │
│  course_poursuite │ Gestion instances/buckets        │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                       NUI                            │
├─────────────────────────────────────────────────────┤
│  index.html       │ Structure DOM                    │
│  style.css        │ Styles et animations             │
│  script.js        │ Logique interface                │
└─────────────────────────────────────────────────────┘
```

### Variables Globales Principales

```lua
-- client/course_poursuite.lua
local inGame = false                -- État du jeu
local currentVehicle = nil          -- Handle du véhicule
local instanceId = nil              -- ID de l'instance
local gameStartTime = nil           -- Timestamp de début
local gameEndTime = nil             -- Timestamp de fin

-- Zone de guerre
local canExitVehicle = false        -- Autorisation sortie
local warZoneActive = false         -- Zone active?
local warZonePosition = nil         -- Position de la zone
local warZoneBlip = nil             -- Handle blip zone
local warZoneCenterBlip = nil       -- Handle blip centre
local warZoneThread = nil           -- Handle thread rendu

-- Threads
local blockExitThread = nil         -- Thread blocage sortie
local zoneCheckThread = nil         -- Thread vérif zone
```

---

## 🔄 Flux de Données

### Démarrage d'une Partie

```
[JOUEUR] Clic "Jouer"
    ↓
[NUI] post('joinCoursePoursuit')
    ↓
[SERVER] Événement 'scharman:server:joinCoursePoursuit'
    ↓
[SERVER] FindOrCreateInstance()
    ↓
[SERVER] AddPlayerToInstance()
    ↓
[SERVER] SetPlayerRoutingBucket()
    ↓
[SERVER] CreateVehicle() → vehicleNetId
    ↓
[SERVER] TriggerClientEvent('scharman:client:startCoursePoursuit')
    ↓
[CLIENT] StartCoursePoursuiteGame(data)
    ↓
[CLIENT] Téléportation
    ↓
[CLIENT] Synchronisation bucket (3s)
    ↓
[CLIENT] Récupération véhicule (NetworkGetEntityFromNetworkId)
    ↓
[CLIENT] Personnalisation véhicule
    ↓
[CLIENT] ForcePlayerIntoVehicle()
    ↓
[CLIENT] Fade in
    ↓
[CLIENT] CreateWarZone() ← ✅ NOUVEAU
    ↓
[CLIENT] StartCountdown() ← ✅ NOUVEAU
    ↓
[CLIENT] StartGameThreads()
    ↓
[JEU EN COURS]
```

### Arrêt d'une Partie

```
[CLIENT/SERVER] Fin détectée
    ↓
[CLIENT] StopCoursePoursuiteGame()
    ↓
[CLIENT] DeleteWarZone() ← ✅ NOUVEAU
    ↓
[CLIENT] DeleteEntity(currentVehicle)
    ↓
[CLIENT] DeleteBot()
    ↓
[CLIENT] Arrêt threads
    ↓
[CLIENT] Reset variables
    ↓
[CLIENT] Téléportation retour
    ↓
[SERVER] RemovePlayerFromInstance()
    ↓
[SERVER] SetPlayerRoutingBucket(0)
    ↓
[FIN PROPRE]
```

---

## ⏱️ Système de Décompte

### Architecture

```lua
-- CLIENT: Démarrage
function StartCountdown()
    countdownActive = true
    FreezeEntityPosition(ped, true)
    
    -- 3
    SendNUIMessage({ action = 'showCountdown', data = { number = 3 }})
    PlaySoundFrontend(...)
    Wait(1000)
    
    -- 2
    SendNUIMessage({ action = 'showCountdown', data = { number = 2 }})
    PlaySoundFrontend(...)
    Wait(1000)
    
    -- 1
    SendNUIMessage({ action = 'showCountdown', data = { number = 1 }})
    PlaySoundFrontend(...)
    Wait(1000)
    
    -- GO!
    SendNUIMessage({ action = 'showCountdown', data = { number = 'GO!' }})
    PlaySoundFrontend(...)
    FreezeEntityPosition(ped, false)
    
    Wait(1000)
    SendNUIMessage({ action = 'hideCountdown' })
    countdownActive = false
end
```

### Communication NUI

```javascript
// JS: Réception
window.addEventListener('message', (event) => {
    switch (event.data.action) {
        case 'showCountdown':
            showCountdown(event.data.data.number);
            break;
        case 'hideCountdown':
            hideCountdown();
            break;
    }
});

// JS: Affichage
function showCountdown(number) {
    Elements.countdownContainer.classList.remove('hidden');
    Elements.countdownNumber.textContent = number;
    
    if (number === 'GO!') {
        Elements.countdownNumber.classList.add('go');
    }
    
    // Forcer reflow pour animation
    Elements.countdownNumber.style.animation = 'none';
    void Elements.countdownNumber.offsetWidth;
    Elements.countdownNumber.style.animation = '';
}
```

### Animations CSS

```css
/* Pulse du chiffre */
@keyframes countdownPulse {
    0% {
        transform: scale(0.5);
        opacity: 0;
    }
    50% {
        transform: scale(1.2);
        opacity: 1;
    }
    100% {
        transform: scale(1);
        opacity: 1;
    }
}

/* Effet ripple */
@keyframes countdownRipple {
    0% {
        transform: scale(0.5);
        opacity: 1;
    }
    100% {
        transform: scale(3);
        opacity: 0;
    }
}

/* Animation GO! */
@keyframes goAnimation {
    0% {
        transform: scale(0.3) rotate(-5deg);
        opacity: 0;
    }
    50% {
        transform: scale(1.5) rotate(5deg);
        opacity: 1;
    }
    100% {
        transform: scale(1) rotate(0deg);
        opacity: 1;
    }
}
```

---

## 🔒 Système de Blocage Véhicule

### Architecture

```lua
-- CLIENT: Thread de blocage
function StartBlockExitThread()
    -- Timer 30 secondes
    CreateThread(function()
        SendNUIMessage({
            action = 'showVehicleLock',
            data = { duration = 30000 }
        })
        
        Wait(30000)
        canExitVehicle = true
        
        SendNUIMessage({ action = 'hideVehicleLock' })
    end)
    
    -- Thread de blocage
    blockExitThread = CreateThread(function()
        while inGame and Config.CoursePoursuit.BlockExitVehicle do
            Wait(0)
            
            if not canExitVehicle then
                -- Bloquer touche F
                DisableControlAction(0, 75, true)
                
                -- Détection tentative
                if IsDisabledControlJustPressed(0, 75) then
                    -- Calculer temps restant
                    local timeElapsed = (GetGameTimer() - gameStartTime) / 1000
                    local timeLeft = math.max(0, 30 - timeElapsed)
                    ShowGameNotification(...)
                end
                
                -- Replacement forcé si sortie
                if not isInVehicle then
                    ForcePlayerIntoVehicle(ped, currentVehicle, -1)
                end
            end
        end
    end)
end
```

### Communication NUI

```javascript
// JS: Affichage avec timer
function showVehicleLock(duration = 30000) {
    Elements.vehicleLockContainer.classList.remove('hidden');
    Elements.vehicleLockProgress.style.width = '100%';
    
    let timeLeft = duration / 1000;
    Elements.vehicleLockTimer.textContent = `${timeLeft}s`;
    
    const startTime = Date.now();
    
    AppState.vehicleLockTimer = setInterval(() => {
        const elapsed = Date.now() - startTime;
        const remaining = Math.max(0, duration - elapsed);
        timeLeft = Math.ceil(remaining / 1000);
        
        // Mettre à jour UI
        Elements.vehicleLockTimer.textContent = `${timeLeft}s`;
        const progress = (remaining / duration) * 100;
        Elements.vehicleLockProgress.style.width = `${progress}%`;
        
        if (remaining <= 0) {
            hideVehicleLock();
        }
    }, 100);
}

function hideVehicleLock() {
    if (AppState.vehicleLockTimer) {
        clearInterval(AppState.vehicleLockTimer);
        AppState.vehicleLockTimer = null;
    }
    
    Elements.vehicleLockContainer.classList.add('hidden');
}
```

### Styles Clés

```css
.vehicle-lock-content {
    background: linear-gradient(135deg, 
        rgba(255, 0, 110, 0.95), 
        rgba(204, 0, 85, 0.95));
    border: 3px solid #ff006e;
    box-shadow: 
        0 10px 40px rgba(255, 0, 110, 0.5),
        0 0 20px rgba(255, 0, 110, 0.3);
}

.lock-icon {
    animation: lockShake 2s infinite;
}

@keyframes lockShake {
    0%, 100% { transform: rotate(0deg); }
    25% { transform: rotate(-10deg); }
    75% { transform: rotate(10deg); }
}

.lock-progress-fill {
    transition: width 1s linear;
    background: linear-gradient(90deg, #ffffff, #ffccdd);
    box-shadow: 0 0 10px rgba(255, 255, 255, 0.5);
}
```

---

## 🔴 Système de Zone de Guerre

### Architecture

```lua
-- CLIENT: Création de la zone
function CreateWarZone(position)
    warZonePosition = position
    warZoneActive = true
    
    -- Blip de rayon (zone)
    warZoneBlip = AddBlipForRadius(
        position.x, position.y, position.z,
        warZoneRadius
    )
    SetBlipHighDetail(warZoneBlip, true)
    SetBlipColour(warZoneBlip, 1) -- Rouge
    SetBlipAlpha(warZoneBlip, 180)
    
    -- Blip centre (crâne)
    warZoneCenterBlip = AddBlipForCoord(
        position.x, position.y, position.z
    )
    SetBlipSprite(warZoneCenterBlip, 84) -- Crâne
    SetBlipDisplay(warZoneCenterBlip, 4)
    SetBlipScale(warZoneCenterBlip, 1.2)
    SetBlipColour(warZoneCenterBlip, 1) -- Rouge
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("🔴 ZONE DE GUERRE")
    EndTextCommandSetBlipName(warZoneCenterBlip)
    
    StartWarZoneThread()
end

-- CLIENT: Thread de rendu
function StartWarZoneThread()
    warZoneThread = CreateThread(function()
        while inGame and warZoneActive and warZonePosition do
            Wait(0) -- Boucle rapide pour rendu fluide
            
            local pos = warZonePosition
            
            -- Colonne de lumière rouge (cylindre vertical)
            DrawMarker(
                28,                              -- Type cylindre
                pos.x, pos.y, pos.z,            -- Position
                0.0, 0.0, 0.0,                  -- Direction
                0.0, 0.0, 0.0,                  -- Rotation
                warZoneRadius,                   -- Largeur
                warZoneRadius,                   -- Profondeur
                150.0,                           -- Hauteur
                255, 0, 0, 100,                 -- RGBA
                false, false, 2, false,
                nil, nil, false
            )
            
            -- Cercle au sol
            DrawMarker(
                1,                               -- Type cylindre plat
                pos.x, pos.y, pos.z - 1.0,     -- Position sous le sol
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                warZoneRadius * 2,               -- Diamètre
                warZoneRadius * 2,
                1.0,                             -- Hauteur
                255, 0, 0, 150,                 -- RGBA
                false, false, 2, false,
                nil, nil, false
            )
        end
        
        warZoneThread = nil
    end)
end

-- CLIENT: Suppression
function DeleteWarZone()
    warZoneActive = false
    warZonePosition = nil
    
    if warZoneBlip then
        RemoveBlip(warZoneBlip)
        warZoneBlip = nil
    end
    
    if warZoneCenterBlip then
        RemoveBlip(warZoneCenterBlip)
        warZoneCenterBlip = nil
    end
    
    warZoneThread = nil
end
```

### Types de Markers

```lua
-- DrawMarker(type, ...)
-- Type 28: Cylindre vertical inversé (colonne de lumière)
-- Type 1: Cylindre plat (cercle au sol)

-- Paramètres DrawMarker:
-- 1. Type (int)
-- 2-4. Position X, Y, Z (float)
-- 5-7. Direction X, Y, Z (float)
-- 8-10. Rotation X, Y, Z (float)
-- 11-13. Scale X, Y, Z (float)
-- 14-17. RGBA (int 0-255)
-- 18. Bob up and down (bool)
-- 19. Face camera (bool)
-- 20. p19 (int)
-- 21. Rotate (bool)
-- 22-23. Texture dict, name (string)
-- 24. Draw on ents (bool)
```

### Configuration

```lua
-- config/course_poursuite.lua
Config.CoursePoursuit.EnableWarZone = true
Config.CoursePoursuit.WarZoneRadius = 50.0
Config.CoursePoursuit.WarZoneColor = {
    r = 255,  -- Rouge
    g = 0,    -- Vert
    b = 0,    -- Bleu
    a = 100   -- Alpha (transparence)
}
Config.CoursePoursuit.WarZoneLightHeight = 150.0
Config.CoursePoursuit.WarZoneBlipSprite = 84 -- Crâne
Config.CoursePoursuit.WarZoneBlipColor = 1 -- Rouge
```

---

## 🧵 Gestion des Threads

### Cycle de Vie

```lua
-- CRÉATION
function StartGameThreads()
    StartBlockExitThread()
    StartZoneCheckThread()
    StartGameTimerThread()
end

-- EXÉCUTION
-- Chaque thread tourne indépendamment
-- avec sa propre boucle Wait()

-- ARRÊT
function StopCoursePoursuiteGame()
    -- Les threads s'arrêtent quand:
    -- 1. inGame = false
    -- 2. La condition de boucle devient false
    -- 3. Les handles sont mis à nil
    
    inGame = false
    blockExitThread = nil
    zoneCheckThread = nil
    warZoneThread = nil
end
```

### Optimisation Wait()

```lua
-- ❌ MAUVAIS: Wait trop court
CreateThread(function()
    while true do
        Wait(0) -- 0ms = CPU utilisé constamment
        -- Code peu critique
    end
end)

-- ✅ BON: Wait adapté
CreateThread(function()
    while true do
        Wait(1000) -- 1 seconde pour vérifications non-critiques
        -- Vérification de zone, timer, etc.
    end
end)

-- ✅ BON: Wait(0) pour rendu
CreateThread(function()
    while warZoneActive do
        Wait(0) -- Nécessaire pour DrawMarker
        DrawMarker(...)
    end
end)
```

---

## 🧹 Nettoyage et Optimisation

### Checklist de Nettoyage

```lua
function StopCoursePoursuiteGame()
    -- 1. État global
    inGame = false
    
    -- 2. Threads (mise à nil)
    blockExitThread = nil
    zoneCheckThread = nil
    warZoneThread = nil
    
    -- 3. Timers
    gameStartTime = nil
    gameEndTime = nil
    
    -- 4. Flags
    canExitVehicle = false
    warZoneActive = false
    countdownActive = false
    
    -- 5. Zone de guerre
    DeleteWarZone() -- Supprime blips + position
    
    -- 6. Véhicules
    if DoesEntityExist(currentVehicle) then
        DeleteEntity(currentVehicle)
        currentVehicle = nil
    end
    
    -- 7. Bot
    DeleteBot() -- Supprime bot + véhicule bot
    
    -- 8. Instance
    instanceId = nil
    
    -- 9. NUI
    SendNUIMessage({ action = 'hideCountdown' })
    SendNUIMessage({ action = 'hideVehicleLock' })
end
```

### Libération de Mémoire

```lua
-- Modèles
LoadModel(modelName)
-- ... utilisation ...
SetModelAsNoLongerNeeded(GetHashKey(modelName))

-- Entités
local entity = CreateVehicle(...)
-- ... utilisation ...
if DoesEntityExist(entity) then
    DeleteEntity(entity)
end

-- Blips
local blip = AddBlipForCoord(...)
-- ... utilisation ...
if DoesBlipExist(blip) then
    RemoveBlip(blip)
end

-- Threads
local thread = CreateThread(function() ... end)
-- ... pour arrêter ...
thread = nil -- Le GC s'occupera du reste
```

### Protection d'Erreur

```lua
-- Utilisation de pcall() pour éviter les crashs
local success, err = pcall(function()
    -- Code potentiellement dangereux
    SetVehicleFuelLevel(vehicle, 100.0)
end)

if not success then
    Config.ErrorPrint('Erreur: ' .. tostring(err))
    -- Nettoyage de secours
    if IsScreenFadedOut() then
        DoScreenFadeIn(500)
    end
end
```

---

## 📡 API NUI

### Messages Lua → NUI

```lua
-- CLIENT
SendNUIMessage({
    action = 'actionName',
    data = {
        key = value
    }
})
```

### Handlers JavaScript

```javascript
// NUI
window.addEventListener('message', (event) => {
    const data = event.data;
    
    switch (data.action) {
        case 'open':
            openInterface(data.data?.animationDuration);
            break;
        case 'showCountdown':
            showCountdown(data.data.number);
            break;
        case 'showVehicleLock':
            showVehicleLock(data.data.duration);
            break;
        // ...
    }
});
```

### Callbacks NUI → Lua

```javascript
// NUI
function post(action, data = {}) {
    fetch(`https://scharman/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
}

post('close', {});
post('joinCoursePoursuit', {});
```

```lua
-- CLIENT
RegisterNUICallback('close', function(data, cb)
    CloseNUI()
    cb('ok')
end)

RegisterNUICallback('joinCoursePoursuit', function(data, cb)
    TriggerServerEvent('scharman:server:joinCoursePoursuit')
    cb('ok')
end)
```

---

## ✅ Bonnes Pratiques

### Code Structure

```lua
-- ✅ BON: Séparation claire
-- Variables en haut
local inGame = false
local currentVehicle = nil

-- Fonctions utilitaires
local function LoadModel(model)
    -- ...
end

-- Fonctions principales
local function StartGame()
    -- ...
end

-- Événements
RegisterNetEvent('event', function()
    -- ...
end)

-- Init
CreateThread(function()
    -- ...
end)
```

### Naming Convention

```lua
-- ✅ BON
local function CreateWarZone()  -- PascalCase pour fonctions
local warZoneActive = false    -- camelCase pour variables
Config.CoursePoursuit.EnableWarZone  -- PascalCase pour configs

-- ❌ MAUVAIS
local function create_war_zone()  -- snake_case
local WarZoneActive = false       -- Confusion avec fonction
```

### Comments

```lua
-- ✅ BON: Commentaires utiles
-- Créer la zone de guerre à la position du joueur
-- Inclut: colonne de lumière + blips + thread de rendu
function CreateWarZone(position)
    -- ...
end

-- ❌ MAUVAIS: Commentaires obvies
-- Mettre warZoneActive à true
warZoneActive = true
```

### Error Handling

```lua
-- ✅ BON: Validation + error handling
function DeleteWarZone()
    if not warZoneActive then
        Config.DebugPrint('Zone déjà inactive')
        return
    end
    
    if warZoneBlip and DoesBlipExist(warZoneBlip) then
        RemoveBlip(warZoneBlip)
    end
    
    warZoneActive = false
    warZonePosition = nil
end

-- ❌ MAUVAIS: Pas de vérification
function DeleteWarZone()
    RemoveBlip(warZoneBlip) -- Crash si blip n'existe pas
    warZoneActive = false
end
```

### Performance

```lua
-- ✅ BON: Cache les valeurs souvent utilisées
local ped = PlayerPedId()
local coords = GetEntityCoords(ped)
local vehicle = GetVehiclePedIsIn(ped, false)

for i = 1, 100 do
    -- Utiliser les variables cachées
    DoSomething(ped, coords)
end

-- ❌ MAUVAIS: Appels répétés
for i = 1, 100 do
    local ped = PlayerPedId()  -- Appelé 100 fois !
    DoSomething(ped)
end
```

---

## 🔍 Debugging

### Logs Structurés

```lua
-- Utiliser les fonctions de logging
Config.DebugPrint('Message de debug')
Config.InfoPrint('Information')
Config.SuccessPrint('Opération réussie')
Config.ErrorPrint('Erreur critique')

-- Logs de sections
Config.InfoPrint('═══ DÉBUT SPAWN BOT ═══')
-- ... code ...
Config.InfoPrint('═══ FIN SPAWN BOT ═══')
```

### Console F8

```bash
# Activer debug
Config.Debug = true

# Observer les logs
[DEBUG] Message
[INFO] Information
[SUCCESS] Réussite
[ERROR] Erreur
```

### Commandes Debug

```lua
RegisterCommand('course_info', function()
    print('═══════════════════════════════════════')
    print('État: ' .. (inGame and 'EN JEU' or 'PAS EN JEU'))
    print('Véhicule: ' .. tostring(currentVehicle))
    print('Zone active: ' .. tostring(warZoneActive))
    print('═══════════════════════════════════════')
end, false)
```

---

**Version** : 2.0.0  
**Auteur** : ESX Legacy (Modifié)  
**Date** : 2025
