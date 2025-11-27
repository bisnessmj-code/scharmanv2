# 🎮 SCHARMAN V3.0.0 - PVP 1v1 MATCHMAKING

Script FiveM de mini-jeux PVP avec système de matchmaking automatique, zone de guerre synchronisée et combat 1v1.

---

## ⚡ NOUVEAUTÉS VERSION 3.0.0

### ✅ Système PVP 1v1 Complet
- **Matchmaking automatique** : Recherche et appairage automatique de deux joueurs
- **Zone de guerre synchronisée** : Le premier joueur qui descend crée la zone, l'adversaire doit la rejoindre
- **Combat équilibré** : Les deux joueurs doivent être dans la zone pour commencer le combat
- **Dégâts hors zone** : Système de dégâts progressifs si vous sortez de la zone
- **Détection de victoire/défaite** : Gestion automatique de la mort et attribution de la victoire

### 🤖 Mode Test avec Bot
- Commande `/botscharman` pour spawner un bot en mode test (si seul en partie)
- Bot désactivé par défaut, uniquement pour les tests

### 🔧 Améliorations Techniques
- **Routing buckets** : Isolation complète des joueurs en partie
- **Synchronisation réseau** : Communication serveur-client optimisée
- **Véhicules personnalisés** : Couleurs différentes pour chaque joueur (Rouge vs Bleu)
- **Gestion déconnexion** : Victoire automatique si l'adversaire quitte

---

## 📥 INSTALLATION

### 1️⃣ Extraire dans `resources/`
```bash
Extraire le ZIP → Renommer en "scharman" → Placer dans resources/
```

### 2️⃣ Configurer les Positions

**Position du PED** → `config/config.lua` ligne 8:
```lua
Config.Ped.coords = vector4(x, y, z, heading)
```

**Positions spawn joueurs** → `config/course_poursuite.lua` lignes 22-25:
```lua
Config.CoursePoursuit.SpawnCoords = {
    player1 = vector4(x, y, z, heading), -- ⚠️ CHANGE-MOI!
    player2 = vector4(x, y, z, heading)  -- ⚠️ CHANGE-MOI!
}
```

**Position retour** → `config/course_poursuite.lua` ligne 28:
```lua
Config.CoursePoursuit.ReturnToNormalCoords = vector4(x, y, z, heading)
```

💡 **Astuce:** Utilise `/scharman_info` en jeu pour copier tes coordonnées !

### 3️⃣ Démarrer
```
ensure scharman
```

---

## 🎯 COMMENT JOUER

### Lancer une Partie PVP
1. Va au PED Scharman
2. Appuie sur **E** pour ouvrir l'interface
3. Clique sur **"Rejoindre le Matchmaking"**
4. Attends qu'un adversaire soit trouvé
5. Tu seras téléporté avec ton adversaire dans des véhicules séparés

### Déroulement de la Partie
1. **Décompte 3-2-1-GO** : Prépare-toi !
2. **Blocage véhicule 30 secondes** : Tu ne peux pas sortir immédiatement
3. **Création de la zone** :
   - Le **premier joueur** qui descend de son véhicule crée la **zone de guerre** à sa position
   - L'**adversaire** voit la zone apparaître sur la carte et doit la **rejoindre**
4. **Entrée dans la zone** :
   - Quand l'adversaire entre dans la zone, le créateur de la zone peut **descendre de son véhicule**
   - Les **deux joueurs** reçoivent un **Pistolet Cal .50**
5. **Combat** :
   - Affrontez-vous dans la zone de guerre (rayon 50m)
   - **ATTENTION** : Si vous sortez de la zone, vous prenez **-20 HP par seconde** !
6. **Victoire** :
   - Tuez votre adversaire pour gagner
   - Si votre adversaire quitte, vous gagnez automatiquement

---

## 🆘 COMMANDES

```lua
/quit_course          -- Quitter la partie en cours
/botscharman          -- [TEST] Spawner un bot si seul en partie
/course_info          -- [DEBUG] Afficher l'état de la partie
/scharman_info        -- Copier position actuelle (pour config)
```

### Commandes Admin
```lua
/course_instances     -- Lister toutes les instances actives
/course_kick [id]     -- Éjecter un joueur d'une partie
```

---

## ⚙️ CONFIGURATION

### Fichier: `config/course_poursuite.lua`

#### Durée de Partie
```lua
Config.CoursePoursuit.GameDuration = 300 -- 5 minutes (0 = infini)
```

#### Zone de Guerre
```lua
Config.CoursePoursuit.WarZoneRadius = 50.0      -- Rayon en mètres
Config.CoursePoursuit.OutOfZoneDamage = 20      -- HP perdus par seconde hors zone
Config.CoursePoursuit.DamageInterval = 1000     -- Délai entre dégâts (ms)
```

#### Arme Donnée
```lua
Config.CoursePoursuit.WeaponHash = 'WEAPON_PISTOL50' -- Cal .50
Config.CoursePoursuit.WeaponAmmo = 250                 -- Munitions
```

#### Véhicules
```lua
Config.CoursePoursuit.VehicleModel = 'sultan'
Config.CoursePoursuit.RandomVehicle = false -- true = aléatoire
```

#### Routing Buckets
```lua
Config.CoursePoursuit.BucketRange = {
    min = 1000,
    max = 2000
}
```

---

## 🎨 SYSTÈME DE COULEURS

### Joueur 1 (Rouge)
- **Véhicule** : Rouge/Noir
- **Plaque** : PLAYER1

### Joueur 2 (Bleu)
- **Véhicule** : Bleu/Noir
- **Plaque** : PLAYER2

### Zone de Guerre
- **Couleur** : Rouge translucide
- **Blip** : Crâne rouge sur la carte
- **Visuel** : Colonne de lumière rouge + cercle au sol

---

## 🐛 DÉPANNAGE

### Pas d'adversaire trouvé ?
- Attends qu'un autre joueur rejoigne le matchmaking
- Utilise `/botscharman` pour tester en solo

### Je ne peux pas descendre du véhicule ?
- **Cas 1** : Attends 30 secondes après le spawn
- **Cas 2** : Si l'adversaire a créé la zone, **rejoins-la d'abord**

### Dégâts ne fonctionnent pas ?
- Assure-toi d'être **hors de la zone** (> 50m du centre)
- Vérifie avec `/course_info` que la zone est active

### L'adversaire a quitté ?
- Tu gagnes automatiquement
- La partie se termine après 3 secondes

---

## 📊 ARCHITECTURE TECHNIQUE

### Client → Serveur
- `scharman:server:joinCoursePoursuit` → Demander matchmaking
- `scharman:server:coursePoursuiteLeft` → Quitter la partie
- `scharman:server:zoneCreated` → J'ai créé la zone de guerre
- `scharman:server:playerEnteredZone` → Je suis entré dans la zone
- `scharman:server:playerDied` → Je suis mort

### Serveur → Client
- `scharman:client:startCoursePoursuit` → Lancer la partie
- `scharman:client:stopCoursePoursuit` → Terminer la partie
- `scharman:client:opponentCreatedZone` → L'adversaire a créé la zone
- `scharman:client:opponentEnteredZone` → L'adversaire est dans la zone
- `scharman:client:opponentDied` → L'adversaire est mort (victoire)
- `scharman:client:courseNotification` → Notification

---

## 🔐 SÉCURITÉ

- **Routing Buckets** : Isolation complète (strict lockdown)
- **Validation serveur** : Toutes les actions importantes validées côté serveur
- **Anti-cheat** : Détection des déconnexions et tricheries basiques
- **Population désactivée** : Pas de PNJ/véhicules dans les buckets de jeu

---

## 📝 CHANGELOG

### Version 3.0.0 (27 Novembre 2025)
- ✅ **NOUVEAU** : Système matchmaking automatique 1v1
- ✅ **NOUVEAU** : Zone de guerre synchronisée entre joueurs
- ✅ **NOUVEAU** : L'adversaire doit rejoindre la zone créée
- ✅ **NOUVEAU** : Détection victoire/défaite automatique
- ✅ **NOUVEAU** : Gestion déconnexion adversaire
- ✅ **NOUVEAU** : Couleurs véhicules différentes par joueur
- ✅ **NOUVEAU** : Commande `/botscharman` pour tests
- 🔧 **MODIFIÉ** : Architecture client-serveur optimisée
- 🔧 **MODIFIÉ** : Suppression spawn bot automatique (sauf `/botscharman`)
- 🔧 **MODIFIÉ** : Messages et notifications améliorés

---

## 📞 SUPPORT

### En cas de problème :
1. Vérifie la console F8 pour les logs
2. Utilise `/course_info` pour l'état de la partie
3. Vérifie que ESX et oxmysql sont bien démarrés
4. Assure-toi que les positions sont bien configurées

---

**Version:** 3.0.0 MATCHMAKING PVP 1V1  
**Date:** 27 Novembre 2025  
**Auteur:** Scharman Dev Team

**🎉 SYSTÈME PVP 1V1 COMPLET - PRÊT POUR LA PRODUCTION !**
