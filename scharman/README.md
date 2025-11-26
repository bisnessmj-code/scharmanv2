# 🎮 SCHARMAN V2.0 - Script FiveM Course Poursuite 1v1

## 🚀 NOUVEAUTÉS VERSION 2.0

### ✅ Fonctionnalités Ajoutées

#### 1. **Décompte 3-2-1-GO**
- Animation visuelle élégante au démarrage de la partie
- Effets sonores synchronisés
- Blocage des contrôles pendant le décompte
- Animation spéciale pour "GO!" avec changement de couleur

#### 2. **Système de Blocage Véhicule Amélioré**
- Interface visuelle moderne avec compte à rebours
- Barre de progression animée (30 secondes)
- Message persistant à l'écran
- Empêche la sortie du véhicule avant la fin du timer
- Replacement automatique si le joueur sort par un bug

#### 3. **Zone de Guerre Immédiate**
- Création automatique dès le spawn
- Colonne de lumière rouge visible de loin (150m de hauteur)
- Blip sur la map avec icône crâne
- Cercle au sol de 50m de rayon
- Suppression automatique à la fin de la partie

#### 4. **Nettoyage Optimisé**
- Suppression complète des véhicules
- Suppression de la zone de guerre
- Suppression des blips
- Libération des threads
- Reset complet des variables
- Changement de bucket à chaque nouvelle partie

## 📋 Architecture V2

```
scharman_v2/
├── client/
│   ├── main.lua              # Initialisation client
│   ├── ped.lua               # Gestion du PED
│   ├── nui.lua               # Interface utilisateur
│   └── course_poursuite.lua  # ✅ LOGIQUE JEU V2 (AMÉLIORÉ)
├── server/
│   ├── main.lua              # Initialisation serveur
│   ├── version.lua           # Vérification dépendances
│   └── course_poursuite.lua  # Gestion instances/buckets
├── config/
│   ├── config.lua            # Configuration générale
│   └── course_poursuite.lua  # ✅ CONFIG JEU V2 (NOUVELLE)
├── html/
│   ├── index.html            # ✅ INTERFACE V2 (DÉCOMPTE + BLOCAGE)
│   ├── css/
│   │   └── style.css         # ✅ STYLES V2 (ANIMATIONS)
│   └── js/
│       └── script.js         # ✅ LOGIQUE V2 (DÉCOMPTE + TIMER)
└── fxmanifest.lua            # Manifest FiveM
```

## 🎯 Fonctionnalités Détaillées

### 🏁 Démarrage de Partie

**Séquence de démarrage :**
1. Joueur appuie sur "Jouer Maintenant"
2. Fermeture de l'interface
3. Téléportation dans la zone de spawn
4. Synchronisation du routing bucket (3s)
5. Récupération/création du véhicule
6. Placement du joueur dans le véhicule
7. **✅ Création immédiate de la zone de guerre**
8. Fade in de l'écran
9. **✅ Décompte 3-2-1-GO avec animations**
10. **✅ Affichage du timer de blocage véhicule (30s)**
11. Début de la partie

### 🔴 Zone de Guerre

**Caractéristiques :**
- **Position** : Coordonnées du spawn du joueur
- **Rayon** : 50 mètres (configurable)
- **Visuel** : 
  - Colonne de lumière rouge (cylindre vertical)
  - Cercle rouge au sol
  - Effet de transparence pour voir à travers
- **Blip Map** :
  - Blip de rayon rouge (zone)
  - Blip crâne au centre
  - Nom : "🔴 ZONE DE GUERRE"
- **Thread de rendu** : Boucle optimisée à 0ms pour rendu fluide

**Suppression :**
- Automatique à la fin de la partie
- Automatique si le joueur quitte (`/quit_course`)
- Suppression des blips
- Arrêt du thread de rendu
- Reset des variables

### 🔒 Système de Blocage Véhicule

**Interface Visuelle :**
```css
┌─────────────────────────────────────┐
│             🔒                       │
│     VÉHICULE VERROUILLÉ              │
│  Vous ne pouvez pas sortir           │
│                                      │
│  Temps restant: 25s                  │
│  ████████████░░░░░░░░ 80%            │
└─────────────────────────────────────┘
```

**Fonctionnalités :**
- Affichage du timer en temps réel
- Barre de progression animée
- Mise à jour toutes les 100ms
- Disparition automatique après 30s
- Notification de fin de blocage

**Protection :**
- Désactive la touche F (sortir véhicule)
- Message d'avertissement si tentative
- Replacement forcé si sortie par bug
- Thread actif pendant toute la durée

### ⏱️ Décompte 3-2-1-GO

**Animations :**
- **Chiffres 3, 2, 1** :
  - Taille : 200px
  - Couleur : Cyan (#00d4ff)
  - Effet de glow/ombre
  - Animation pulse + scale
  - Effet ripple (cercle qui s'agrandit)
  - Son : "CHECKPOINT_NORMAL"

- **GO!** :
  - Taille : 200px
  - Couleur : Vert (#00ff88)
  - Animation spéciale avec rotation
  - Son : "RACE_PLACED"

**Durée totale** : 4 secondes
- 3 : 1 seconde
- 2 : 1 seconde
- 1 : 1 seconde
- GO! : 1 seconde

**Effets :**
- Fond noir semi-transparent (70%)
- Z-index 9999 (au-dessus de tout)
- Blocage des mouvements du joueur (FreezeEntityPosition)
- Déblocage automatique après "GO!"

## ⚙️ Configuration

### Fichier `config/course_poursuite.lua`

#### Paramètres du Décompte
```lua
-- Activer le décompte 3-2-1-GO au spawn
Config.CoursePoursuit.EnableCountdown = true
```

#### Paramètres du Blocage Véhicule
```lua
-- Empêcher le joueur de sortir du véhicule
Config.CoursePoursuit.BlockExitVehicle = true

-- Durée du blocage (en secondes)
Config.CoursePoursuit.BlockExitDuration = 30
```

#### Paramètres de la Zone de Guerre
```lua
-- Activer la zone de guerre automatique
Config.CoursePoursuit.EnableWarZone = true

-- Rayon de la zone (en mètres)
Config.CoursePoursuit.WarZoneRadius = 50.0

-- Couleur de la zone (RGBA)
Config.CoursePoursuit.WarZoneColor = {
    r = 255,
    g = 0,
    b = 0,
    a = 100
}

-- Hauteur de la colonne de lumière
Config.CoursePoursuit.WarZoneLightHeight = 150.0

-- Type de blip (84 = Crâne)
Config.CoursePoursuit.WarZoneBlipSprite = 84

-- Couleur du blip (1 = Rouge)
Config.CoursePoursuit.WarZoneBlipColor = 1
```

## 🔧 Installation

### 1. Placement du Script
```bash
# Copier le dossier dans resources/
resources/
└── scharman_v2/
```

### 2. Configuration server.cfg
```bash
ensure scharman_v2
```

### 3. Configuration de la Position du PED
Dans `config/config.lua` :
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

### 4. Configuration du Spawn de Jeu
Dans `config/course_poursuite.lua` :
```lua
-- Point de spawn du joueur
Config.CoursePoursuit.SpawnCoords = vector4(-2124.83, -301.81, 13.09, 73.70)
```

### 5. Configuration de Retour
Dans `config/course_poursuite.lua` :
```lua
-- Position de retour après la partie
Config.CoursePoursuit.ReturnToNormalCoords = vector4(-2148.92, -330.63, 12.99, 141.73)
```

### 6. Redémarrage
```bash
restart scharman_v2
# ou
refresh
ensure scharman_v2
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
- `/course_info` - Afficher les infos détaillées

### Admin
- `/course_instances` - Lister les instances actives
- `/course_kick [id]` - Éjecter un joueur de la course
- `/scharman_list` - Lister les joueurs avec l'interface ouverte

## 🐛 Debug

### Activer les Logs Détaillés
```lua
-- Dans config/config.lua
Config.Debug = true

-- Dans config/course_poursuite.lua
Config.CoursePoursuit.DebugMode = true
```

### Logs à Surveiller

#### ✅ Démarrage Réussi
```
[INFO] DÉMARRAGE DE LA COURSE POURSUITE V2
[SUCCESS] Véhicule récupéré: 12345
[SUCCESS] Joueur placé dans le véhicule avec succès!
[INFO] 🔴 CRÉATION ZONE DE GUERRE
[SUCCESS] Zone de guerre créée à la position: vector3(...)
[INFO] ⏱️ DÉMARRAGE DU DÉCOMPTE
[SUCCESS] ✅ Décompte terminé - C'EST PARTI!
[SUCCESS] COURSE POURSUITE V2 DÉMARRÉE!
```

#### ✅ Logs Zone de Guerre
```
[INFO] 🔴 CRÉATION ZONE DE GUERRE
[SUCCESS] Zone de guerre créée à la position: vector3(-2124.83, -301.81, 13.09)
[DEBUG] Blip zone de guerre créé
[INFO] Thread de rendu zone de guerre démarré
```

#### ✅ Logs Nettoyage
```
[INFO] ARRÊT DU MODE COURSE POURSUITE V2
[DEBUG] Suppression de la zone de guerre...
[SUCCESS] Zone de guerre supprimée
[DEBUG] Véhicule joueur supprimé
[SUCCESS] NETTOYAGE TERMINÉ
```

## 📊 Optimisations

### Performance
- **Thread de zone de guerre** : Boucle à 0ms pour rendu fluide
- **Thread de blocage véhicule** : Boucle à 0ms pour détection instantanée
- **Mise à jour timer** : 100ms pour économiser les ressources
- **Nettoyage automatique** : Suppression de tous les threads à l'arrêt

### Mémoire
- Libération des modèles après utilisation
- Suppression des entités à la fin
- Reset des variables globales
- Arrêt des timers/intervals

## 🎨 Personnalisation

### Modifier les Couleurs du Décompte
Dans `html/css/style.css` :
```css
.countdown-number {
    color: #00d4ff; /* Couleur des chiffres */
}

.countdown-number.go {
    color: #00ff88; /* Couleur de GO! */
}
```

### Modifier l'Interface de Blocage
Dans `html/css/style.css` :
```css
.vehicle-lock-content {
    background: linear-gradient(135deg, rgba(255, 0, 110, 0.95), rgba(204, 0, 85, 0.95));
    border: 3px solid #ff006e;
}
```

### Modifier la Zone de Guerre
Dans `config/course_poursuite.lua` :
```lua
-- Rayon (en mètres)
Config.CoursePoursuit.WarZoneRadius = 75.0

-- Couleur (RGBA)
Config.CoursePoursuit.WarZoneColor = {
    r = 0,   -- Rouge : 0-255
    g = 255, -- Vert : 0-255
    b = 0,   -- Bleu : 0-255
    a = 100  -- Alpha : 0-255
}

-- Hauteur de la colonne
Config.CoursePoursuit.WarZoneLightHeight = 200.0
```

## 🔍 Dépannage

### Le décompte ne s'affiche pas
1. Vérifier la console F8 pour les erreurs JavaScript
2. Vérifier que `index.html` contient l'élément `#countdown-container`
3. Vérifier que `style.css` contient les styles `.countdown-container`
4. S'assurer que `Config.CoursePoursuit.EnableCountdown = true`

### Le message de blocage ne s'affiche pas
1. Vérifier la console F8
2. Vérifier que `Config.CoursePoursuit.BlockExitVehicle = true`
3. Vérifier que l'élément `#vehicle-lock-container` existe
4. Vérifier les styles `.vehicle-lock-container`

### La zone de guerre n'apparaît pas
1. Vérifier que `Config.CoursePoursuit.EnableWarZone = true`
2. Vérifier les logs : "CRÉATION ZONE DE GUERRE"
3. Vérifier que le thread de rendu est démarré
4. S'assurer d'être dans le bon routing bucket

### Les véhicules ne se suppriment pas
1. Vérifier les logs de nettoyage
2. S'assurer que `StopCoursePoursuiteGame()` est appelé
3. Vérifier que `DeleteEntity()` fonctionne
4. Essayer `/quit_course` manuellement

### Écran noir au démarrage
- Le code inclut une protection automatique avec `pcall()`
- Vérifier les logs d'erreur
- Le fade in se fait toujours même en cas d'erreur
- Utiliser `/quit_course` pour forcer la sortie

## 📞 Support

Pour tout problème :
1. Activer `Config.Debug = true`
2. Reproduire le bug
3. Copier les logs de la console (F8)
4. Vérifier cette documentation
5. Contacter le support avec les logs

## 🎯 Améliorations Futures Possibles

### Suggestions
- [ ] Système de points/score
- [ ] Classement des joueurs
- [ ] Power-ups dans la zone
- [ ] Mode 2v2 ou Battle Royale
- [ ] Checkpoints de course
- [ ] Système de ranking
- [ ] Récompenses en fin de partie
- [ ] Statistiques personnelles
- [ ] Modes de jeu supplémentaires

---

**Version** : 2.0.0  
**Auteur** : ESX Legacy (Modifié)  
**Date** : 2025  
**License** : MIT

## ✨ Remerciements

- ESX Legacy pour le framework
- La communauté FiveM
- Tous les testeurs

---

**⚡ SCHARMAN V2 - Prêt pour l'action !**
