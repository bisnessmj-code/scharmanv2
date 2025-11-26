# 📝 CHANGELOG - SCHARMAN

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

---

## [2.0.0] - 2025-01-XX

### 🎉 Ajouté

#### Interface Utilisateur
- **Décompte 3-2-1-GO** au démarrage de la partie
  - Animation visuelle élégante en plein écran
  - Effet de pulse et ripple sur les chiffres
  - Animation spéciale pour "GO!" avec changement de couleur
  - Sons synchronisés avec les animations
  - Z-index élevé (9999) pour être au-dessus de tout
  - Fond noir semi-transparent pour meilleure lisibilité

- **Message de Blocage Véhicule** persistant
  - Interface visuelle moderne avec icône de cadenas
  - Timer en temps réel (mise à jour toutes les 100ms)
  - Barre de progression animée
  - Design rouge/rose pour indiquer l'interdiction
  - Animation de shake sur l'icône
  - Position en bas de l'écran (bottom: 100px)
  - Disparition automatique après 30 secondes

#### Gameplay
- **Zone de Guerre** créée automatiquement au spawn
  - Colonne de lumière rouge visible de loin (150m de hauteur)
  - Cercle au sol de 50 mètres de rayon
  - Effet de transparence pour voir à travers
  - Thread de rendu optimisé à 0ms
  - Couleurs personnalisables (RGBA)
  - Rayon configurable

- **Système de Blips** pour la zone de guerre
  - Blip de rayon (cercle rouge sur la map)
  - Blip centre avec icône crâne (sprite 84)
  - Nom : "🔴 ZONE DE GUERRE"
  - Alpha de 180 pour bonne visibilité
  - Suppression automatique à la fin

#### Configuration
- `Config.CoursePoursuit.EnableCountdown` - Activer/désactiver le décompte
- `Config.CoursePoursuit.BlockExitDuration` - Durée du blocage en secondes
- `Config.CoursePoursuit.EnableWarZone` - Activer/désactiver la zone de guerre
- `Config.CoursePoursuit.WarZoneRadius` - Rayon de la zone (mètres)
- `Config.CoursePoursuit.WarZoneColor` - Couleur RGBA de la zone
- `Config.CoursePoursuit.WarZoneLightHeight` - Hauteur de la colonne (mètres)
- `Config.CoursePoursuit.WarZoneBlipSprite` - Type de blip pour le centre
- `Config.CoursePoursuit.WarZoneBlipColor` - Couleur du blip
- Nouvelles notifications dans `Config.CoursePoursuit.Notifications`

#### Code
- Fonction `StartCountdown()` - Gestion du décompte avec animations
- Fonction `CreateWarZone(position)` - Création de la zone de guerre
- Fonction `DeleteWarZone()` - Suppression propre de la zone
- Fonction `StartWarZoneThread()` - Thread de rendu de la zone
- Fonction `showCountdown(number)` (JS) - Affichage du décompte
- Fonction `hideCountdown()` (JS) - Masquage du décompte
- Fonction `showVehicleLock(duration)` (JS) - Affichage message blocage
- Fonction `hideVehicleLock()` (JS) - Masquage message blocage
- Handler `showCountdown` dans l'event listener (JS)
- Handler `hideCountdown` dans l'event listener (JS)
- Handler `showVehicleLock` dans l'event listener (JS)
- Handler `hideVehicleLock` dans l'event listener (JS)

#### Documentation
- README.md complet avec toutes les nouvelles fonctionnalités
- MIGRATION.md pour passer de V1 à V2
- CHANGELOG.md détaillé
- Commentaires de code améliorés
- Bannières ASCII dans les fichiers

### ⚡ Amélioré

#### Performance
- Thread de zone de guerre optimisé (boucle à 0ms)
- Thread de blocage véhicule optimisé (boucle à 0ms)
- Mise à jour du timer toutes les 100ms au lieu de 1000ms
- Nettoyage automatique de tous les threads à l'arrêt
- Libération immédiate des modèles après utilisation

#### Nettoyage
- Suppression complète des véhicules à la fin de partie
- Suppression de la zone de guerre et de tous ses éléments
- Suppression des blips (zone + centre)
- Arrêt des threads de rendu
- Reset de toutes les variables globales
- Arrêt des timers/intervals JavaScript
- Nettoyage même en cas d'erreur (pcall)

#### Interface
- Animations CSS plus fluides
- Transitions améliorées
- Meilleure gestion du z-index
- Responsive design préservé
- Styles modernisés

#### Logique
- Gestion d'erreur améliorée avec pcall()
- Logs plus détaillés et structurés
- Séparation claire des fonctionnalités
- Code mieux commenté
- Architecture plus modulaire

#### Sécurité
- Protection contre l'écran noir renforcée
- Fade in/out garanti même en cas d'erreur
- Validation des entités avant suppression
- Vérification des threads avant création
- Protection contre les doublons

### 🔧 Corrigé

#### Bugs Critiques
- **Zone de guerre** : Maintenant créée et supprimée correctement
- **Véhicules fantômes** : Suppression garantie à la fin
- **Blips persistants** : Nettoyage complet des blips
- **Threads zombies** : Arrêt propre de tous les threads
- **Mémoire** : Pas de fuite mémoire (libération des ressources)

#### Bugs Mineurs
- Placement du joueur dans le véhicule plus fiable
- Synchronisation du routing bucket améliorée
- Timers qui ne se mettaient pas à jour correctement
- Variables globales qui n'étaient pas reset
- Messages NUI qui s'empilaient

### 🗑️ Déprécié

Rien dans cette version.

### ❌ Supprimé

- Ancienne méthode de création de véhicule client-side (remplacée par serveur-side)
- Code mort et commentaires obsolètes
- Logs de debug redondants

### 🔒 Sécurité

- Validation stricte des entités avant opération
- Protection contre les injections dans les messages NUI
- Vérification des permissions pour les commandes admin
- Sanitization des entrées utilisateur

---

## [1.1.0] - 2025-01-XX

### 🎉 Ajouté

#### Gameplay
- Mode solo avec bot adversaire
- Système de routing buckets pour instances isolées
- Véhicule créé serveur-side avec Network ID
- Blocage de sortie du véhicule pendant 30 secondes
- Système de zone de jeu limitée (optionnel)
- Timer de partie configurable

#### Bot Adversaire
- Spawn automatique en mode solo
- Conduite autonome avec IA
- Véhicule personnalisé
- Comportement configurable (vitesse, style)
- Route aléatoire ou vers point précis

#### Configuration
- `Config.CoursePoursuit.AllowSolo` - Mode solo
- `Config.CoursePoursuit.SpawnBotInSolo` - Activer bot
- `Config.CoursePoursuit.BotModel` - Modèle du bot
- `Config.CoursePoursuit.BotVehicle` - Véhicule du bot
- `Config.CoursePoursuit.BotSpeed` - Vitesse du bot
- `Config.CoursePoursuit.BotDrivingStyle` - Style de conduite
- `Config.CoursePoursuit.BlockExitVehicle` - Bloquer sortie

#### Commandes
- `/quit_course` - Quitter la partie
- `/course_stop` - Arrêter (debug)
- `/course_info` - Infos détaillées (debug)
- `/course_instances` - Lister instances (admin)
- `/course_kick [id]` - Éjecter joueur (admin)

### ⚡ Amélioré

- Système de placement dans véhicule (10 tentatives)
- Gestion des erreurs avec pcall()
- Logs plus détaillés
- Protection écran noir

### 🔧 Corrigé

- Joueur ne spawnait pas dans le véhicule
- Bot ne spawnait pas correctement
- Véhicule disparaissait après création
- Écran noir au démarrage
- Synchronisation bucket

---

## [1.0.0] - 2025-01-XX

### 🎉 Version Initiale

#### Interface
- Interface tablette moderne
- Menu de sélection de modes
- Système de notifications
- Design futuriste cyan/bleu

#### PED
- Spawn du PED avec marker 3D
- Blip sur la map
- Interaction avec touche E
- Scénario configurable

#### Système de Base
- Framework ESX
- Dépendance oxmysql
- Mode debug
- Logs colorés

#### Configuration
- Position du PED
- Coordonnées de spawn
- Modèle de véhicule
- Couleurs personnalisables

---

## 📊 Statistiques des Versions

### V2.0.0
- **Fichiers modifiés** : 6
- **Lignes ajoutées** : ~800
- **Nouvelles fonctions** : 12
- **Nouvelles configs** : 10
- **Bugs corrigés** : 8

### V1.1.0
- **Fichiers modifiés** : 4
- **Lignes ajoutées** : ~500
- **Nouvelles fonctions** : 8
- **Nouvelles configs** : 12
- **Bugs corrigés** : 5

### V1.0.0
- **Fichiers créés** : 15
- **Lignes de code** : ~2000
- **Fonctions** : 30+
- **Configs** : 50+

---

## 🎯 Roadmap Futur

### Version 2.1.0 (Prévu)
- [ ] Système de points/score
- [ ] Classement des joueurs
- [ ] Statistiques personnelles
- [ ] Récompenses en fin de partie

### Version 2.2.0 (Prévu)
- [ ] Mode 2v2
- [ ] Mode Battle Royale
- [ ] Power-ups dans la zone
- [ ] Checkpoints de course

### Version 3.0.0 (Idées)
- [ ] Système de ranking
- [ ] Tournois automatiques
- [ ] Saisons compétitives
- [ ] Intégration Discord

---

## 📝 Notes

### Format de Versioning
- **X.0.0** : Changements majeurs, refonte complète
- **0.X.0** : Nouvelles fonctionnalités importantes
- **0.0.X** : Corrections de bugs, petites améliorations

### Types de Changements
- **Ajouté** : Nouvelles fonctionnalités
- **Amélioré** : Modifications de fonctionnalités existantes
- **Déprécié** : Fonctionnalités bientôt supprimées
- **Supprimé** : Fonctionnalités retirées
- **Corrigé** : Corrections de bugs
- **Sécurité** : Corrections de vulnérabilités

---

**Dernière mise à jour** : 2025-01-XX  
**Auteur** : ESX Legacy (Modifié)  
**License** : MIT
