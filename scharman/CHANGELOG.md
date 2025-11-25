# 📝 Changelog - Scharman PED

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Versioning Sémantique](https://semver.org/lang/fr/).

---

## [1.0.0] - 2025-11-25

### 🎉 Version initiale

#### ✨ Ajouté
- **Système de PED interactif**
  - Spawn automatique du PED au démarrage
  - Configuration complète de la position, modèle, et animations
  - Gestion intelligente du cycle de vie (spawn/suppression)
  
- **Blip sur la carte**
  - Blip personnalisable (sprite, couleur, échelle)
  - Option pour affichage courte/longue portée
  - Label configurable

- **Marqueur 3D**
  - Marqueur au sol avec affichage dynamique selon la distance
  - Texte d'aide personnalisable
  - Couleurs RGBA configurables
  - Animation de rotation

- **Interface NUI (Tablette)**
  - Design moderne et futuriste
  - Animations d'ouverture/fermeture fluides
  - Effet de flou d'arrière-plan
  - Gestion du focus et des contrôles
  - 4 cartes de modes de jeu (placeholder pour développement futur)
  - Section d'informations en temps réel
  - Design responsive (PC et tablette)

- **Système de configuration**
  - Fichier `config.lua` centralisé
  - Plus de 50 paramètres configurables
  - Fonctions utilitaires de logging (Debug, Error, Success, Info)
  - Configuration des performances

- **Mode Debug**
  - Logs détaillés dans la console F8
  - Commandes de debug client (`/scharman_info`, `/scharman_reload`, etc.)
  - Commandes admin serveur (`/scharman_list`)
  - Mode debug JavaScript dans l'interface NUI

- **Optimisations**
  - Threads optimisés avec attentes dynamiques
  - Render distance pour le PED
  - Nettoyage automatique des ressources
  - Libération des modèles après utilisation
  - Gestion intelligente de la distance de vérification

- **Exports**
  - Exports client pour ouvrir/fermer l'interface
  - Exports pour vérifier l'état de l'interface
  - Exports pour obtenir les coordonnées du PED
  - Exports serveur pour la gestion des joueurs

- **Documentation**
  - README.md complet avec toutes les informations
  - Code entièrement commenté en français
  - Exemples d'utilisation pour développeurs
  - Guide de personnalisation

- **Architecture**
  - Structure modulaire et organisée
  - Séparation client/serveur/config/html
  - Code propre et maintenable
  - Respect des bonnes pratiques FiveM

#### 🔧 Technique
- Compatible ESX Legacy
- Support oxmysql
- Lua 5.4
- HTML5 + CSS3 + JavaScript moderne
- Fonts Google (Orbitron + Rajdhani)

#### 📊 Performances
- Consommation : 0.01-0.03ms (idle), 0.05-0.10ms (interface ouverte)
- Optimisation des threads et du rendu
- Gestion efficace de la mémoire

---

## [À venir] - Versions futures

### Version 1.1.0 (Planifié)
- [ ] Système de matchmaking 1v1
- [ ] Mode Gunfight avec armes aléatoires
- [ ] Système de files d'attente
- [ ] Statistiques de combat
- [ ] Intégration avec routing buckets

### Version 1.2.0 (Planifié)
- [ ] Mode tournoi
- [ ] Classement global
- [ ] Système de récompenses
- [ ] Mode équipe (2v2, 3v3)
- [ ] Statistiques avancées

### Version 2.0.0 (Futur)
- [ ] Refonte de l'interface
- [ ] Multi-langues
- [ ] API pour développeurs
- [ ] Intégration Discord Rich Presence
- [ ] Système de saisons et de progression

---

## 📌 Types de changements

- **✨ Ajouté** : Nouvelles fonctionnalités
- **🔧 Modifié** : Changements dans des fonctionnalités existantes
- **🐛 Corrigé** : Corrections de bugs
- **🗑️ Supprimé** : Fonctionnalités supprimées
- **🔒 Sécurité** : Corrections de vulnérabilités
- **⚡ Performances** : Améliorations de performances
- **📝 Documentation** : Changements dans la documentation

---

*Dernière mise à jour : 25 novembre 2025*
