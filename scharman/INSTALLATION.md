# 🚀 Guide d'installation rapide - Scharman PED

Ce guide vous accompagne étape par étape pour installer le script sur votre serveur FiveM.

---

## ⏱️ Temps d'installation estimé : **5 minutes**

---

## 📋 Checklist avant installation

Assurez-vous d'avoir :
- ✅ Un serveur FiveM fonctionnel
- ✅ ESX Legacy installé et configuré
- ✅ oxmysql installé et configuré
- ✅ Accès FTP ou accès direct aux fichiers du serveur
- ✅ Accès au fichier `server.cfg`

---

## 📦 Étape 1 : Téléchargement

1. Téléchargez le fichier `scharman_ped.zip`
2. Extrayez l'archive sur votre ordinateur
3. Vous devriez avoir un dossier `scharman_ped` avec cette structure :

```
scharman_ped/
├── fxmanifest.lua
├── README.md
├── config/
├── client/
├── server/
└── html/
```

---

## 📂 Étape 2 : Upload des fichiers

### Option A : Via FTP (recommandé)

1. Connectez-vous à votre serveur via FTP (FileZilla, WinSCP, etc.)
2. Naviguez vers le dossier `resources`
3. Créez ou accédez au dossier `[standalone]` (ou `[custom]`)
4. Uploadez le dossier `scharman_ped` complet

**Chemin final** : `resources/[standalone]/scharman_ped/`

### Option B : Via panneau d'hébergement

1. Accédez à votre panneau d'hébergement (Pterodactyl, etc.)
2. Allez dans le gestionnaire de fichiers
3. Naviguez vers `resources/[standalone]/`
4. Uploadez le ZIP et extrayez-le directement

---

## ⚙️ Étape 3 : Configuration du server.cfg

1. Ouvrez votre fichier `server.cfg`
2. Ajoutez cette ligne **après** ESX et oxmysql :

```cfg
# Scharman PED - Interface Tablette
ensure scharman_ped
```

**Exemple de configuration complète** :

```cfg
# ESX Legacy
ensure es_extended
ensure oxmysql

# Scripts standalone
ensure scharman_ped  # <-- Nouvelle ligne

# Vos autres scripts
ensure esx_billing
# ...
```

---

## 🎯 Étape 4 : Configuration du script

1. Ouvrez le fichier `scharman_ped/config/config.lua`
2. Modifiez la position du PED selon vos besoins :

```lua
Config.Ped = {
    coords = vector4(215.68, -810.12, 30.73, 250.0),
    -- Changez ces coordonnées par celles de votre choix
}
```

### 📍 Comment obtenir vos coordonnées ?

**Méthode 1 : Via commande temporaire**

Ajoutez temporairement cette commande dans un script :

```lua
RegisterCommand('pos', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    print(string.format('vector4(%.2f, %.2f, %.2f, %.2f)', coords.x, coords.y, coords.z, heading))
end)
```

**Méthode 2 : Utiliser le script**

1. Allez à l'endroit souhaité
2. Notez les coordonnées (X, Y, Z) et le heading (direction)
3. Remplacez dans le config

### 🎨 Personnalisation rapide (optionnel)

```lua
-- Changer le modèle du PED
Config.Ped.model = 'a_m_y_business_03'

-- Changer le nom du blip
Config.Blip.label = 'Votre texte ici'

-- Activer/désactiver le debug
Config.Debug = true  -- true pour développement, false pour production
```

---

## 🔄 Étape 5 : Démarrage

### Option A : Redémarrage complet du serveur

1. Arrêtez votre serveur
2. Attendez quelques secondes
3. Redémarrez le serveur
4. Le script se chargera automatiquement

### Option B : Sans redémarrage

Dans la console serveur ou F8 :

```
refresh
start scharman_ped
```

Ou via txAdmin :
1. Allez dans "Resources"
2. Cliquez sur "Refresh"
3. Recherchez "scharman_ped"
4. Cliquez sur "Start"

---

## ✅ Étape 6 : Vérification

### Dans la console serveur

Vous devriez voir :

```
[Scharman PED] ═══════════════════════════════════════
[Scharman PED] Script Scharman PED démarré avec succès!
[Scharman PED] Version: 1.0.0
[Scharman PED] ═══════════════════════════════════════
```

### En jeu

1. Connectez-vous au serveur
2. Ouvrez votre carte (M)
3. Vous devriez voir un **blip bleu avec une icône tablette**
4. Allez à cet endroit
5. Vous devriez voir un **PED** avec un **marqueur bleu au sol**
6. Appuyez sur **E** pour ouvrir l'interface

---

## 🐛 Résolution de problèmes

### Le script ne démarre pas

**Erreur** : `Failed to load script scharman_ped`

**Solution** :
1. Vérifiez que le dossier est bien nommé `scharman_ped` (pas de version, pas d'espaces)
2. Vérifiez que le `fxmanifest.lua` existe
3. Vérifiez les permissions des fichiers (lecture activée)

### Le PED n'apparaît pas

**Causes possibles** :
- Mauvaises coordonnées
- ESX non chargé
- Script démarré trop tôt

**Solutions** :
1. Vérifiez dans F8 : `/scharman_info`
2. Utilisez `/scharman_reload`
3. Changez les coordonnées dans le config

### L'interface ne s'ouvre pas

**Causes possibles** :
- Trop loin du PED
- Fichiers HTML manquants

**Solutions** :
1. Approchez-vous à moins de 2.5m
2. Vérifiez que le dossier `html` existe
3. Essayez `/scharman_open` dans F8

### Erreurs dans la console

```
[ERROR] oxmysql n'est pas démarré
```
→ Démarrez oxmysql avant scharman_ped dans le server.cfg

```
[ERROR] ESX n'est pas chargé
```
→ Vérifiez qu'ESX Legacy est bien installé et démarré

---

## 📞 Support

Si vous rencontrez des problèmes :

1. **Vérifiez d'abord** :
   - Les logs dans la console serveur
   - Les logs dans F8 (client)
   - Que toutes les dépendances sont installées

2. **Consultez** :
   - Le fichier `README.md` (documentation complète)
   - La section "Résolution de problèmes"

3. **Demandez de l'aide** :
   - Discord ESX Legacy : https://discord.esx-framework.org/
   - Forums FiveM

---

## ✨ Félicitations !

Votre script Scharman PED est maintenant installé et fonctionnel ! 🎉

**Prochaines étapes** :
- Personnalisez l'apparence dans `html/css/style.css`
- Ajoutez votre logique de jeu
- Consultez le `README.md` pour les fonctionnalités avancées

---

**Bon développement ! 🚀**

*Guide d'installation - Version 1.0.0*
