// ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
// ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
// ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
// ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
// ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
// ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
// JAVASCRIPT - Logique de l'interface Scharman
// ═══════════════════════════════════════════════════════════════

/**
 * ═══════════════════════════════════════════════════════════════
 * CONFIGURATION & VARIABLES GLOBALES
 * ═══════════════════════════════════════════════════════════════
 */

// État de l'application
const AppState = {
    isOpen: false,
    isAnimating: false,
    debugMode: true
};

// Éléments DOM
const Elements = {
    app: null,
    closeBtn: null,
    gameCards: []
};

/**
 * ═══════════════════════════════════════════════════════════════
 * FONCTIONS UTILITAIRES
 * ═══════════════════════════════════════════════════════════════
 */

/**
 * Log en mode debug
 * @param {string} message - Message à logger
 * @param {string} type - Type de log (info, warning, error, success)
 */
function debugLog(message, type = 'info') {
    if (!AppState.debugMode) return;
    
    const styles = {
        info: 'color: #00d4ff; font-weight: bold;',
        warning: 'color: #ffbe0b; font-weight: bold;',
        error: 'color: #ff006e; font-weight: bold;',
        success: 'color: #00ff88; font-weight: bold;'
    };
    
    console.log(`%c[Scharman NUI] ${message}`, styles[type] || styles.info);
    
    // Envoyer le log au client Lua (si en jeu)
    if (typeof post === 'function') {
        post('log', { message: message, type: type });
    }
}

/**
 * Envoyer des données au client Lua
 * @param {string} action - Action à exécuter
 * @param {object} data - Données à envoyer
 */
function post(action, data = {}) {
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    })
    .then(response => response.json())
    .then(result => {
        debugLog(`Callback ${action} reçu avec succès`, 'success');
    })
    .catch(error => {
        debugLog(`Erreur lors du callback ${action}: ${error}`, 'error');
    });
}

/**
 * Obtenir le nom de la ressource parente
 * @returns {string} Nom de la ressource
 */
function GetParentResourceName() {
    let resourceName = 'scharman_ped';
    
    // Essayer d'obtenir le nom via window.location
    if (window.location.hostname !== '') {
        const splitUrl = window.location.pathname.split('/');
        resourceName = splitUrl[splitUrl.length - 2] || resourceName;
    }
    
    return resourceName;
}

/**
 * ═══════════════════════════════════════════════════════════════
 * GESTION DE L'INTERFACE
 * ═══════════════════════════════════════════════════════════════
 */

/**
 * Ouvrir l'interface
 * @param {number} animationDuration - Durée de l'animation (en ms)
 */
function openInterface(animationDuration = 500) {
    if (AppState.isOpen || AppState.isAnimating) {
        debugLog('Interface déjà ouverte ou en cours d\'animation', 'warning');
        return;
    }
    
    debugLog('Ouverture de l\'interface...', 'info');
    AppState.isAnimating = true;
    
    // Afficher le conteneur
    Elements.app.classList.remove('hidden');
    
    // Attendre la fin de l'animation
    setTimeout(() => {
        AppState.isOpen = true;
        AppState.isAnimating = false;
        debugLog('Interface ouverte avec succès', 'success');
        
        // Focus sur le bouton de fermeture
        Elements.closeBtn.focus();
    }, animationDuration);
}

/**
 * Fermer l'interface
 * @param {number} animationDuration - Durée de l'animation (en ms)
 */
function closeInterface(animationDuration = 400) {
    if (!AppState.isOpen || AppState.isAnimating) {
        debugLog('Interface déjà fermée ou en cours d\'animation', 'warning');
        return;
    }
    
    debugLog('Fermeture de l\'interface...', 'info');
    AppState.isAnimating = true;
    
    // Ajouter la classe de fermeture
    Elements.app.classList.add('closing');
    
    // Attendre la fin de l'animation
    setTimeout(() => {
        Elements.app.classList.remove('closing');
        Elements.app.classList.add('hidden');
        AppState.isOpen = false;
        AppState.isAnimating = false;
        debugLog('Interface fermée avec succès', 'success');
        
        // Notifier le client Lua
        post('close');
    }, animationDuration);
}

/**
 * ═══════════════════════════════════════════════════════════════
 * GESTION DES ÉVÉNEMENTS DOM
 * ═══════════════════════════════════════════════════════════════
 */

/**
 * Initialiser les écouteurs d'événements
 */
function initEventListeners() {
    debugLog('Initialisation des écouteurs d\'événements...', 'info');
    
    // Bouton de fermeture
    Elements.closeBtn.addEventListener('click', () => {
        debugLog('Clic sur le bouton de fermeture', 'info');
        closeInterface();
    });
    
    // Écouteur clavier (ESC pour fermer)
    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && AppState.isOpen) {
            debugLog('Touche ESC détectée', 'info');
            closeInterface();
        }
    });
    
    // Empêcher le clic droit
    document.addEventListener('contextmenu', (event) => {
        event.preventDefault();
        return false;
    });
    
    // Gestion des cartes de jeu (pour les futures fonctionnalités)
    Elements.gameCards.forEach((card, index) => {
        card.addEventListener('click', () => {
            handleCardClick(index);
        });
        
        // Effets hover personnalisés
        card.addEventListener('mouseenter', () => {
            card.style.transform = 'translateY(-5px) scale(1.02)';
        });
        
        card.addEventListener('mouseleave', () => {
            card.style.transform = 'translateY(0) scale(1)';
        });
    });
    
    debugLog('Écouteurs d\'événements initialisés', 'success');
}

/**
 * Gérer le clic sur une carte de jeu
 * @param {number} cardIndex - Index de la carte cliquée
 */
function handleCardClick(cardIndex) {
    debugLog(`Clic sur la carte ${cardIndex}`, 'info');
    
    // Vérifier si le bouton est désactivé
    const button = Elements.gameCards[cardIndex].querySelector('.btn-primary');
    if (button && button.disabled) {
        debugLog('Carte désactivée', 'warning');
        
        // Animation de "shake" pour indiquer que c'est désactivé
        Elements.gameCards[cardIndex].style.animation = 'none';
        setTimeout(() => {
            Elements.gameCards[cardIndex].style.animation = 'shake 0.5s ease';
        }, 10);
        
        return;
    }
    
    // TODO: Gérer la logique pour chaque type de carte
    // Vous pouvez envoyer des données au client Lua ici
}

/**
 * ═══════════════════════════════════════════════════════════════
 * GESTION DES MESSAGES DU CLIENT LUA
 * ═══════════════════════════════════════════════════════════════
 */

/**
 * Recevoir des messages du client Lua
 */
window.addEventListener('message', (event) => {
    const data = event.data;
    
    // Vérifier que les données sont valides
    if (!data || !data.action) return;
    
    debugLog(`Message reçu: ${data.action}`, 'info');
    
    // Router les actions
    switch (data.action) {
        case 'open':
            openInterface(data.data?.animationDuration || 500);
            break;
            
        case 'close':
            closeInterface(data.data?.animationDuration || 400);
            break;
            
        case 'updateData':
            updateInterfaceData(data.data);
            break;
            
        case 'ping':
            post('ping', { timestamp: Date.now() });
            break;
            
        default:
            debugLog(`Action inconnue: ${data.action}`, 'warning');
            break;
    }
});

/**
 * Mettre à jour les données de l'interface
 * @param {object} data - Données à mettre à jour
 */
function updateInterfaceData(data) {
    debugLog('Mise à jour des données de l\'interface', 'info');
    
    // TODO: Implémenter la mise à jour des données
    // Exemple: mise à jour du nombre de joueurs, statistiques, etc.
}

/**
 * ═══════════════════════════════════════════════════════════════
 * INITIALISATION
 * ═══════════════════════════════════════════════════════════════
 */

/**
 * Initialiser l'application
 */
function init() {
    debugLog('═══════════════════════════════════════════════════════════════', 'info');
    debugLog('Initialisation de Scharman NUI...', 'info');
    debugLog('═══════════════════════════════════════════════════════════════', 'info');
    
    // Récupérer les éléments DOM
    Elements.app = document.getElementById('app');
    Elements.closeBtn = document.getElementById('closeBtn');
    Elements.gameCards = Array.from(document.querySelectorAll('.game-card'));
    
    // Vérifier que tous les éléments sont présents
    if (!Elements.app || !Elements.closeBtn) {
        debugLog('Erreur: Éléments DOM manquants!', 'error');
        return;
    }
    
    // Initialiser les écouteurs d'événements
    initEventListeners();
    
    // Masquer l'interface au démarrage
    Elements.app.classList.add('hidden');
    
    // Test de connexion avec le client Lua
    post('ping', { message: 'Interface chargée' });
    
    debugLog('═══════════════════════════════════════════════════════════════', 'info');
    debugLog('Scharman NUI initialisé avec succès!', 'success');
    debugLog('═══════════════════════════════════════════════════════════════', 'info');
}

/**
 * ═══════════════════════════════════════════════════════════════
 * ANIMATIONS PERSONNALISÉES
 * ═══════════════════════════════════════════════════════════════
 */

// Ajouter un style pour l'animation shake
const shakeStyle = document.createElement('style');
shakeStyle.textContent = `
    @keyframes shake {
        0%, 100% { transform: translateX(0); }
        25% { transform: translateX(-10px); }
        75% { transform: translateX(10px); }
    }
`;
document.head.appendChild(shakeStyle);

/**
 * ═══════════════════════════════════════════════════════════════
 * DÉMARRAGE DE L'APPLICATION
 * ═══════════════════════════════════════════════════════════════
 */

// Attendre que le DOM soit complètement chargé
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}

/**
 * ═══════════════════════════════════════════════════════════════
 * EXPORTS (pour tests et debugging)
 * ═══════════════════════════════════════════════════════════════
 */

// Exposer certaines fonctions pour le debugging en console
if (AppState.debugMode) {
    window.ScharmanDebug = {
        open: () => openInterface(),
        close: () => closeInterface(),
        state: AppState,
        elements: Elements,
        post: post
    };
    
    debugLog('Mode debug activé. Utilisez window.ScharmanDebug pour accéder aux fonctions', 'info');
}
