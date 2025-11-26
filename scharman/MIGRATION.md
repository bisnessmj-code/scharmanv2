# 🔄 Guide de Migration - V1.1.0 vers V2.0.0

## 📋 Vue d'ensemble

Ce guide vous accompagne dans la migration de votre script Scharman de la version 1.1.0 vers la version 2.0.0.

**⚠️ IMPORTANT** : Faites une sauvegarde complète avant de commencer !

---

## 🎯 Principales Différences

### Nouveautés V2.0
- ✅ Décompte 3-2-1-GO avec animations
- ✅ Interface de blocage véhicule (30s)
- ✅ Zone de guerre immédiate
- ✅ Nettoyage optimisé
- ✅ Meilleure gestion des entités

### Fichiers Modifiés
- `client/course_poursuite.lua` - **COMPLÈTEMENT REFAIT**
- `html/index.html` - **AJOUT** de nouveaux containers
- `html/css/style.css` - **AJOUT** de nouveaux styles
- `html/js/script.js` - **AJOUT** de nouvelles fonctions
- `config/course_poursuite.lua` - **AJOUT** de nouveaux paramètres
- `fxmanifest.lua` - **MIS À JOUR** version 2.0.0

### Fichiers Inchangés
- `client/main.lua` - ✅ Compatible
- `client/ped.lua` - ✅ Compatible
- `client/nui.lua` - ✅ Compatible
- `server/main.lua` - ✅ Compatible
- `server/version.lua` - ✅ Compatible
- `server/course_poursuite.lua` - ✅ Compatible
- `config/config.lua` - ✅ Compatible

---

## 📦 Méthode 1 : Installation Propre (Recommandée)

### Étape 1 : Sauvegarde
```bash
# Renommer l'ancien dossier
mv resources/scharman resources/scharman_backup

# Sauvegarder votre configuration
cp resources/scharman_backup/config/config.lua ~/config_backup.lua
cp resources/scharman_backup/config/course_poursuite.lua ~/course_poursuite_backup.lua
```

### Étape 2 : Installation V2
```bash
# Copier le nouveau dossier
cp -r scharman_v2 resources/scharman_v2

# Restaurer vos configurations personnalisées
# (positions, coordonnées, etc.)
```

### Étape 3 : Configuration
1. Ouvrir `config/config.lua`
2. Mettre à jour `Config.Ped.coords` avec votre position de PED
3. Ouvrir `config/course_poursuite.lua`
4. Mettre à jour `Config.CoursePoursuit.SpawnCoords`
5. Mettre à jour `Config.CoursePoursuit.ReturnToNormalCoords`

### Étape 4 : Server.cfg
```bash
# Remplacer dans server.cfg
ensure scharman_v2

# OU si vous gardez le nom "scharman"
# Renommer le dossier
mv resources/scharman_v2 resources/scharman
```

### Étape 5 : Test
```bash
# Redémarrer le serveur ou
restart scharman_v2
# ou
restart scharman
```

---

## 🔧 Méthode 2 : Mise à Jour Manuelle (Avancée)

### Fichiers à Remplacer Complètement

#### 1. `client/course_poursuite.lua`
```bash
# Sauvegarder l'ancien
cp client/course_poursuite.lua client/course_poursuite_OLD.lua

# Copier le nouveau
cp scharman_v2/client/course_poursuite.lua client/course_poursuite.lua
```

**✅ Pourquoi remplacer ?**
- Architecture complètement refaite
- Nouvelles fonctions pour décompte
- Nouvelles fonctions pour zone de guerre
- Nettoyage optimisé
- Plus de 200 lignes de nouvelles fonctionnalités

#### 2. `html/index.html`
```bash
# Sauvegarder l'ancien
cp html/index.html html/index_OLD.html

# Copier le nouveau
cp scharman_v2/html/index.html html/index.html
```

**✅ Éléments ajoutés :**
```html
<!-- Décompte -->
<div id="countdown-container" class="countdown-container hidden">
    <div class="countdown-number">3</div>
    <div class="countdown-pulse"></div>
</div>

<!-- Blocage Véhicule -->
<div id="vehicle-lock-container" class="vehicle-lock-container hidden">
    <!-- Contenu du message -->
</div>
```

#### 3. `html/css/style.css`
```bash
# Option A : Remplacer complètement
cp scharman_v2/html/css/style.css html/css/style.css

# Option B : Ajouter à la fin du fichier existant
cat scharman_v2/html/css/style_additions.css >> html/css/style.css
```

**✅ Sections ajoutées :**
- `.countdown-container` et animations
- `.vehicle-lock-container` et animations
- Keyframes pour les animations

#### 4. `html/js/script.js`
```bash
# Sauvegarder l'ancien
cp html/js/script.js html/js/script_OLD.js

# Copier le nouveau
cp scharman_v2/html/js/script.js html/js/script.js
```

**✅ Fonctions ajoutées :**
- `showCountdown(number)`
- `hideCountdown()`
- `showVehicleLock(duration)`
- `hideVehicleLock()`
- Handlers pour les nouveaux messages

#### 5. `config/course_poursuite.lua`
```bash
# Sauvegarder l'ancien
cp config/course_poursuite.lua config/course_poursuite_OLD.lua

# Copier le nouveau (puis remettre vos valeurs personnalisées)
cp scharman_v2/config/course_poursuite.lua config/course_poursuite.lua
```

**✅ Nouveaux paramètres :**
```lua
-- Décompte
Config.CoursePoursuit.EnableCountdown = true

-- Blocage véhicule
Config.CoursePoursuit.BlockExitDuration = 30

-- Zone de guerre
Config.CoursePoursuit.EnableWarZone = true
Config.CoursePoursuit.WarZoneRadius = 50.0
Config.CoursePoursuit.WarZoneColor = {r = 255, g = 0, b = 0, a = 100}
Config.CoursePoursuit.WarZoneLightHeight = 150.0
Config.CoursePoursuit.WarZoneBlipSprite = 84
Config.CoursePoursuit.WarZoneBlipColor = 1

-- Nouvelles notifications
Config.CoursePoursuit.Notifications.countdownStart = "⏱️ Préparez-vous..."
Config.CoursePoursuit.Notifications.vehicleLocked = "🔒 Véhicule verrouillé"
Config.CoursePoursuit.Notifications.warZoneCreated = "🔴 ZONE DE GUERRE créée!"
```

#### 6. `fxmanifest.lua`
```bash
# Mettre à jour la version
version '2.0.0'
description 'Script PED Scharman avec Interface Tablette + Course Poursuite 1v1 V2.0'
```

---

## ⚙️ Configuration Post-Migration

### 1. Vérifier les Positions

**PED de spawn :**
```lua
-- Dans config/config.lua
Config.Ped.coords = vector4(x, y, z, heading)
```

**Zone de jeu :**
```lua
-- Dans config/course_poursuite.lua
Config.CoursePoursuit.SpawnCoords = vector4(x, y, z, heading)
```

**Retour après jeu :**
```lua
-- Dans config/course_poursuite.lua
Config.CoursePoursuit.ReturnToNormalCoords = vector4(x, y, z, heading)
```

### 2. Activer les Nouvelles Fonctionnalités

```lua
-- Dans config/course_poursuite.lua

-- Décompte 3-2-1-GO
Config.CoursePoursuit.EnableCountdown = true

-- Blocage véhicule 30s
Config.CoursePoursuit.BlockExitVehicle = true
Config.CoursePoursuit.BlockExitDuration = 30

-- Zone de guerre
Config.CoursePoursuit.EnableWarZone = true
Config.CoursePoursuit.WarZoneRadius = 50.0
```

### 3. Personnalisation (Optionnel)

**Couleurs de la zone :**
```lua
Config.CoursePoursuit.WarZoneColor = {
    r = 255,  -- Rouge (0-255)
    g = 0,    -- Vert (0-255)
    b = 0,    -- Bleu (0-255)
    a = 100   -- Transparence (0-255)
}
```

**Rayon de la zone :**
```lua
Config.CoursePoursuit.WarZoneRadius = 75.0 -- Mètres
```

**Hauteur de la colonne :**
```lua
Config.CoursePoursuit.WarZoneLightHeight = 200.0 -- Mètres
```

---

## ✅ Checklist de Migration

### Avant Migration
- [ ] Sauvegarde complète du dossier `scharman`
- [ ] Sauvegarde des fichiers de configuration
- [ ] Note des positions personnalisées
- [ ] Test du serveur en mode backup

### Pendant Migration
- [ ] Arrêt du script : `stop scharman`
- [ ] Remplacement des fichiers
- [ ] Mise à jour de la configuration
- [ ] Vérification du `server.cfg`

### Après Migration
- [ ] Redémarrage : `restart scharman_v2`
- [ ] Vérification console (F8) : Pas d'erreurs
- [ ] Test du PED : Apparition correcte
- [ ] Test de l'interface : Ouverture/fermeture
- [ ] Test du jeu :
  - [ ] Téléportation fonctionne
  - [ ] Véhicule spawn correctement
  - [ ] Décompte 3-2-1-GO s'affiche
  - [ ] Message de blocage véhicule apparaît
  - [ ] Zone de guerre visible
  - [ ] Blips sur la map
  - [ ] Fin de partie propre
  - [ ] Retour à la normale
  - [ ] Véhicule/zone supprimés

---

## 🐛 Problèmes Courants

### Le décompte ne s'affiche pas
**Solution :**
1. Vérifier que `html/index.html` contient `#countdown-container`
2. Vérifier que `html/css/style.css` contient les styles `.countdown-*`
3. Vérifier que `html/js/script.js` contient `showCountdown()`
4. Vérifier la console F8 pour erreurs JavaScript

### Le message de blocage ne fonctionne pas
**Solution :**
1. Vérifier `Config.CoursePoursuit.BlockExitVehicle = true`
2. Vérifier `#vehicle-lock-container` dans HTML
3. Vérifier les styles `.vehicle-lock-*`
4. Vérifier `showVehicleLock()` dans JS

### La zone de guerre n'apparaît pas
**Solution :**
1. Vérifier `Config.CoursePoursuit.EnableWarZone = true`
2. Vérifier les logs : "CRÉATION ZONE DE GUERRE"
3. Vérifier que vous êtes dans le bon bucket
4. Essayer d'ajuster `WarZoneRadius`

### Erreurs dans la console
**Solution :**
1. Activer `Config.Debug = true`
2. Reproduire le problème
3. Copier les logs complets
4. Vérifier que tous les fichiers sont à jour
5. Comparer avec les fichiers de référence V2

---

## 📊 Comparaison des Versions

| Fonctionnalité | V1.1.0 | V2.0.0 |
|----------------|--------|--------|
| Décompte visuel | ❌ | ✅ |
| Message blocage véhicule | ❌ | ✅ |
| Zone de guerre au spawn | ❌ | ✅ |
| Colonne de lumière | ❌ | ✅ |
| Blips de zone | ❌ | ✅ |
| Nettoyage optimisé | ⚠️ | ✅ |
| Animations HTML/CSS | ⚠️ | ✅ |
| Timer de progression | ❌ | ✅ |
| Thread de rendu zone | ❌ | ✅ |

---

## 🎯 Rollback vers V1.1.0

Si vous rencontrez des problèmes avec la V2 :

```bash
# Arrêter le script
stop scharman_v2

# Restaurer la sauvegarde
rm -rf resources/scharman_v2
mv resources/scharman_backup resources/scharman

# Redémarrer
ensure scharman
```

---

## 📞 Support Post-Migration

Si vous avez des questions ou des problèmes :

1. ✅ Vérifier ce guide de migration
2. ✅ Lire le [README.md](README.md)
3. ✅ Activer le mode debug
4. ✅ Copier les logs
5. ✅ Contacter le support avec :
   - Version utilisée
   - Logs console (F8)
   - Description du problème
   - Étapes pour reproduire

---

**Bonne migration ! 🚀**

Version du guide : 2.0.0  
Date : 2025
