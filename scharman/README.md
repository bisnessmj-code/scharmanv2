# 🎮 SCHARMAN V2.0.5 ULTRA-DEBUG - PARFAIT

Script FiveM de mini-jeux interactifs avec système de course-poursuite, bot IA, zone de guerre et logs ultra-détaillés pour debugging.

---

## ⚡ INSTALLATION EN 3 ÉTAPES

### 1️⃣ Extraire dans `resources/`
```bash
Extraire le ZIP → Renommer en "scharman" → Placer dans resources/
```

### 2️⃣ Configurer les 3 Positions

**Position du PED** → `config/config.lua` ligne 8:
```lua
Config.Ped.coords = vector4(x, y, z, heading)
```

**Position spawn partie** → `config/course_poursuite.lua` ligne 8:
```lua
Config.CoursePoursuit.SpawnCoords = vector4(x, y, z, heading)
```

**Position retour** → `config/course_poursuite.lua` ligne 11:
```lua
Config.CoursePoursuit.ReturnToNormalCoords = vector4(x, y, z, heading)
```

💡 **Astuce:** Utilise `/scharman_info` en jeu pour copier tes coordonnées !

### 3️⃣ Démarrer
```
ensure scharman
```

---

## 🆕 VERSION 2.0.5 - PARFAIT (3 CORRECTIONS CRITIQUES)

### 🔧 Corrections V2.0.5:
- ✅ **Plus de ragdoll** : Tu ne tombes plus au sol quand tu perds de la vie hors zone !
- ✅ **Écran de mort lisible** : Lueur du texte réduite (20px → 5-15px), texte facile à lire !
- ✅ **Résurrection après mort** : NetworkResurrectLocalPlayer() + SetEntityHealth(200) après téléportation !
- ✅ **Erreur vector corrigée** : Conversion vector3() pour calcul distance (ligne 1097 + 1125)

### ⚡ Améliorations V2.0.4:
- ✅ **Bot spawn IMMÉDIAT** : Plus besoin d'attendre 3 secondes, il spawn en même temps que toi !
- ✅ **Bot va vers la zone** : Quand tu descends du véhicule, le bot se dirige automatiquement vers la zone de guerre !
- ✅ **Dégâts zone 100% fonctionnels** : Correction ordre des fonctions (forward declaration)
- ✅ **Arme retirée à la fin** : RemoveAllPedWeapons() appelé quand tu quittes la partie

### ⚠️ Correctif Hot-Fix V2.0.3:
- ✅ **SetEntityRoutingBucket() retiré** côté client (fonction SERVEUR uniquement)
- ✅ **Bot LOCAL hérite automatiquement** du bucket du joueur
- ✅ **Plus d'erreur au spawn bot** - Le bot spawn correctement maintenant !

### Corrections V2.0.2:

#### 🤖 Spawn Bot Refondu:
- ✅ **Création LOCAL (non-networked)** → Évite problèmes sync réseau
- ✅ **Désactivation population temporaire** → Force le spawn sans compétition
- ✅ **12 étapes tracées** avec logs ultra-détaillés
- ✅ **Attente prolongée 10 secondes** (50 tentatives × 200ms)
- ✅ **Vérifications complètes** : DoesEntityExist, IsEntityAPed, GetEntityType, position, health

#### 🔴 Thread Dégâts Corrigé:
- ✅ **Démarre APRÈS création zone** (correction critique)
- ✅ **Logs détaillés** : cycle, distance, HP, avertissements
- ✅ **Message persistant** hors zone toutes les 2 secondes
- ✅ **Détection mort** automatique avec écran

---

## 🔧 COMMANDES F8

```lua
/course_info          -- État complet du jeu
/scharman_info       -- Copier position actuelle
/quit_course         -- Quitter la partie
```

---

## 🐛 DÉPANNAGE

### Bot ne spawn pas?
1. Vérifier F8 pendant spawn (logs détaillés)
2. Envoyer TOUS les logs depuis "[BOT] DÉBUT SPAWN BOT"

### Dégâts ne fonctionnent pas?
1. `/course_info` → "Zone créée: OUI"
2. S'éloigner de plus de 50m

---

**Version:** 2.0.5 ULTRA-DEBUG PARFAIT  
**Date:** 26 Novembre 2025  

**🎉 VERSION PARFAITE - Plus de ragdoll + Écran mort lisible + Résurrection OK !**
