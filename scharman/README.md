# 🎮 SCHARMAN - Script FiveM Course Poursuite 1v1

## 📋 Problèmes Résolus

Cette version corrige les problèmes suivants :

### ✅ Problème de spawn dans le véhicule
- **Problème** : Le joueur ne spawnait pas correctement dans le véhicule
- **Solution** : Système robuste de placement avec plusieurs tentatives et vérifications
- **Méthodes utilisées** : 
  - `TaskWarpPedIntoVehicle()` avec retry
  - `SetPedIntoVehicle()` en fallback
  - Vérifications en boucle avec timeout

### ✅ Problème de spawn du bot
- **Problème** : Le bot ne spawnait pas dans son véhicule
- **Solution** : Même système robuste appliqué au bot
- **Améliorations** : 
  - Attente de stabilisation du véhicule
  - Placement forcé avec vérifications
  - Logs détaillés à chaque étape

### ✅ Debug logs complets
- **Ajouté** : Logs détaillés à chaque étape du processus
- **Sections loggées** :
  - Chargement des modèles
  - Création des entités
  - Placement dans les véhicules
  - État des threads
  - Vérifications de conditions

### ✅ Commande de sortie
- **Nouvelle commande** : `/quit_course`
- **Fonction** : Quitte la partie en cours et téléporte au PED
- **Aussi disponible** : `/course_stop` (en mode debug)

## 🚀 Installation

1. **Extraire le dossier** `scharman` dans votre dossier `resources/`
2. **Ajouter dans server.cfg** :
   ```
   ensure scharman
   ```
3. **Configurer la position du PED** dans `config/config.lua` :
   ```lua
   Config.Ped = {
       model = 'a_m_y_business_03',
       coords = vector4(x, y, z, heading), -- VOTRE POSITION
       scenario = 'WORLD_HUMAN_CLIPBOARD',
       invincible = true,
       freeze = true,
       blockEvents = true
   }
   ```

4. **Redémarrer le serveur** :
   ```
   restart scharman
   ```

## 🎮 Commandes Disponibles

### Joueur
- `/quit_course` - Quitter la partie en cours

### Debug (si Config.Debug = true)
- `/scharman_info` - Afficher la position actuelle
- `/scharman_reload` - Recharger le PED
- `/scharman_open` - Ouvrir l'interface
- `/scharman_close` - Fermer l'interface
- `/scharman_toggle` - Toggle l'interface
- `/course_stop` - Arrêter la course
- `/course_info` - Afficher les infos de la partie

### Admin
- `/course_instances` - Lister les instances actives
- `/course_kick [id]` - Éjecter un joueur de la course
- `/scharman_list` - Lister les joueurs avec l'interface ouverte

## ⚙️ Configuration

### Mode Solo
Dans `config/course_poursuite.lua` :
```lua
Config.CoursePoursuit.AllowSolo = true -- Permettre le mode solo
Config.CoursePoursuit.SpawnBotInSolo = true -- Spawner un bot en solo
Config.CoursePoursuit.BotsInSolo = 1 -- Nombre de bots
```

### Véhicules
```lua
Config.CoursePoursuit.VehicleModel = 'sultan' -- Modèle par défaut
Config.CoursePoursuit.BotVehicle = 'futo' -- Véhicule du bot
Config.CoursePoursuit.RandomVehicle = false -- Véhicule aléatoire
```

### Zone de spawn
```lua
Config.CoursePoursuit.SpawnCoords = vector4(-2124.83, -301.81, 13.09, 73.70)
```

### Durée de partie
```lua
Config.CoursePoursuit.GameDuration = 300 -- 5 minutes (0 = infini)
```

## 🐛 Debug

Pour activer les logs de debug détaillés :
```lua
Config.Debug = true -- dans config/config.lua
Config.CoursePoursuit.DebugMode = true -- dans config/course_poursuite.lua
```

Les logs affichent :
- Chargement des modèles
- Création des véhicules et PEDs
- Placement dans les véhicules (avec tentatives)
- État des threads
- Événements réseau
- Erreurs avec stack trace

## 📝 Logs à surveiller

### ✅ Spawn réussi
```
[INFO] DÉMARRAGE DE LA COURSE POURSUITE
[DEBUG] Chargement du modèle de véhicule...
[SUCCESS] Modèle chargé: sultan
[DEBUG] Création du véhicule joueur...
[SUCCESS] Véhicule créé: 12345
[DEBUG] Placement du joueur dans le véhicule...
[DEBUG] Tentative 1/10 de placement...
[SUCCESS] Joueur placé dans le véhicule avec succès!
```

### ❌ Échec de spawn (ancien code)
```
[ERROR] Le joueur n'est pas dans le véhicule!
```

### ✅ Nouveau code
```
[DEBUG] Tentative 1/10 de placement...
[DEBUG] Tentative 2/10 de placement...
[SUCCESS] Joueur placé dans le véhicule avec succès!
```

## 🔧 Dépannage

### Le joueur ne spawn pas dans le véhicule
1. Vérifier que `Config.Debug = true`
2. Regarder les logs console
3. Vérifier les coordonnées de spawn
4. S'assurer que la zone est dégagée

### Le bot ne spawn pas
1. Vérifier `Config.CoursePoursuit.SpawnBotInSolo = true`
2. Vérifier les modèles dans la config
3. Regarder les logs "═══ DÉBUT SPAWN BOT ═══"

### Écran noir
- Le code inclut une protection contre l'écran noir
- Le fade in se fait automatiquement même en cas d'erreur

## 📊 Architecture

```
scharman/
├── client/
│   ├── main.lua          # Initialisation client
│   ├── ped.lua           # Gestion du PED
│   ├── nui.lua           # Interface utilisateur
│   └── course_poursuite.lua # Logique du jeu (CORRIGÉ)
├── server/
│   ├── main.lua          # Initialisation serveur
│   ├── version.lua       # Vérification dépendances
│   └── course_poursuite.lua # Gestion instances/buckets
├── config/
│   ├── config.lua        # Configuration générale
│   └── course_poursuite.lua # Configuration du jeu
├── html/
│   ├── index.html        # Interface
│   ├── css/style.css     # Styles
│   └── js/script.js      # Logique NUI
└── fxmanifest.lua        # Manifest FiveM
```

## 🎯 Améliorations Principales

### client/course_poursuite.lua
- ✅ Fonction `ForcePlayerIntoVehicle()` robuste
- ✅ Système de retry avec timeout
- ✅ Fallback sur `SetPedIntoVehicle()`
- ✅ Logs détaillés à chaque étape
- ✅ Vérifications de l'état du véhicule
- ✅ Protection contre l'écran noir avec pcall
- ✅ Gestion d'erreur améliorée
- ✅ Commande `/quit_course`

### SpawnBotAdversary()
- ✅ Même système robuste pour le bot
- ✅ Vérifications multiples
- ✅ Logs "═══ DÉBUT/FIN SPAWN BOT ═══"
- ✅ Gestion d'échec gracieuse

## 📞 Support

Pour tout problème :
1. Activer `Config.Debug = true`
2. Copier les logs de la console (F8)
3. Vérifier la section "Dépannage" ci-dessus
4. Contacter le support avec les logs

---

**Version** : 1.1.0 (CORRIGÉE)
**Auteur** : ESX Legacy (Modifié)
**Date** : 2025
