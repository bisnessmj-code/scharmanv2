// ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
// ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
// ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
// ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
// ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
// ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
// JAVASCRIPT - VERSION FINALE AVEC COURSE POURSUITE
// ═══════════════════════════════════════════════════════════════

/**
 * ═══════════════════════════════════════════════════════════════
 * VARIABLES GLOBALES
 * ═══════════════════════════════════════════════════════════════
 */

const AppState = {
    isOpen: false,
    isAnimating: false,
    debugMode: true
};

const Elements = {
    app: null,
    closeBtn: null,
    gameCards: [],
    notificationContainer: null
};

/**
 * ═══════════════════════════════════════════════════════════════
 * SYSTÈME DE NOTIFICATIONS
 * ═══════════════════════════════════════════════════════════════
 */

/**
 * Afficher une notification en jeu
 * @param {string} message - Message à afficher
 * @param {number} duration - Durée en ms
 * @param {string} type - Type: 'info', 'success', 'warning', 'error'
 */
function showNotification(message, duration = 3000, type = 'info') {
    // Créer l'élément de notification
    const notification = document.createElement('div');
    notification.className = `game-notification ${type}`;
    notification.textContent = message;
    
    // Ajouter la barre de progression
    notification.style.setProperty('--duration', `${duration}ms`);
    const progressBar = notification.querySelector('::before');
    if (progressBar) {
        progressBar.style.animationDuration = `${duration}ms`;
    }
    
    // Ajouter au conteneur
    Elements.notificationContainer.appendChild(notification);
    
    // Log
    debugLog(`Notification: ${message} (${type})`, type === 'error' ? 'error' : 'info');
    
    // Retirer après la durée
    setTimeout(() => {
        notification.classList.add('closing');
        setTimeout(() => {
            if (notification.parentElement) {
                notification.parentElement.removeChild(notification);
            }
        }, 300);
    }, duration);
}

/**
 * ═══════════════════════════════════════════════════════════════
 * FONCTIONS UTILITAIRES
 * ═══════════════════════════════════════════════════════════════
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
}

/**
 * Envoyer un callback à Lua
 */
function post(action, data = {}) {
    fetch(`https://scharman/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify(data)
    }).then(resp => resp.json()).then(resp => {
        debugLog(`✓ Callback ${action} réussi`, 'success');
    }).catch(error => {
        debugLog(`✗ Callback ${action} échoué: ${error}`, 'error');
    });
}

/**
 * ═══════════════════════════════════════════════════════════════
 * GESTION DE L'INTERFACE
 * ═══════════════════════════════════════════════════════════════
 */

function openInterface(animationDuration = 500) {
    if (AppState.isOpen || AppState.isAnimating) return;
    
    debugLog('Ouverture de l\'interface...', 'info');
    AppState.isAnimating = true;
    
    Elements.app.classList.remove('hidden');
    
    setTimeout(() => {
        AppState.isOpen = true;
        AppState.isAnimating = false;
        debugLog('Interface ouverte', 'success');
        Elements.closeBtn.focus();
    }, animationDuration);
}

function closeInterface(animationDuration = 400) {
    if (!AppState.isOpen || AppState.isAnimating) return;
    
    debugLog('Fermeture de l\'interface...', 'info');
    AppState.isAnimating = true;
    
    Elements.app.classList.add('closing');
    
    setTimeout(() => {
        Elements.app.classList.remove('closing');
        Elements.app.classList.add('hidden');
        AppState.isOpen = false;
        AppState.isAnimating = false;
        debugLog('Interface fermée', 'success');
        
        // Notifier Lua
        post('close');
    }, animationDuration);
}

/**
 * ═══════════════════════════════════════════════════════════════
 * GESTION DES MODES DE JEU
 * ═══════════════════════════════════════════════════════════════
 */

/**
 * Lancer le mode Course Poursuite
 */
function startCoursePoursuiteMode() {
    debugLog('Lancement du mode Course Poursuite', 'info');
    
    // Afficher une notification
    showNotification('🏁 Recherche d\'une partie...', 2000, 'info');
    
    // Fermer l'interface
    closeInterface();
    
    // Attendre que l'interface soit fermée
    setTimeout(() => {
        // Envoyer le callback à Lua pour démarrer le jeu
        post('joinCoursePoursuit', {});
    }, 500);
}

/**
 * Gérer le clic sur une carte de jeu
 */
function handleCardClick(cardElement, index) {
    debugLog(`Clic sur la carte ${index}`, 'info');
    
    // Récupérer le mode de jeu
    const gameMode = cardElement.getAttribute('data-mode');
    
    // Vérifier si le bouton est désactivé
    const button = cardElement.querySelector('.btn-primary');
    if (button && button.disabled) {
        debugLog('Mode désactivé', 'warning');
        showNotification('❌ Ce mode de jeu n\'est pas encore disponible', 2000, 'warning');
        
        // Animation shake
        cardElement.style.animation = 'none';
        setTimeout(() => {
            cardElement.style.animation = 'shake 0.5s ease';
        }, 10);
        
        return;
    }
    
    // Router vers le bon mode
    switch (gameMode) {
        case 'course':
            startCoursePoursuiteMode();
            break;
        
        default:
            debugLog('Mode inconnu: ' + gameMode, 'warning');
            showNotification('❌ Mode de jeu non reconnu', 2000, 'error');
            break;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════
 * ÉVÉNEMENTS DOM
 * ═══════════════════════════════════════════════════════════════
 */

function initEventListeners() {
    debugLog('Initialisation des écouteurs...', 'info');
    
    // Bouton fermeture
    Elements.closeBtn.addEventListener('click', () => {
        debugLog('Clic fermeture', 'info');
        closeInterface();
    });
    
    // Touche ESC
    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && AppState.isOpen) {
            debugLog('ESC détecté', 'info');
            closeInterface();
        }
    });
    
    // Désactiver clic droit
    document.addEventListener('contextmenu', (e) => e.preventDefault());
    
    // Cartes de jeu
    Elements.gameCards.forEach((card, index) => {
        // Clic sur la carte entière
        card.addEventListener('click', () => handleCardClick(card, index));
        
        // Clic sur le bouton (pour éviter double événement)
        const button = card.querySelector('.btn-primary');
        if (button) {
            button.addEventListener('click', (e) => {
                e.stopPropagation();
                if (!button.disabled) {
                    handleCardClick(card, index);
                }
            });
        }
        
        // Effets hover
        card.addEventListener('mouseenter', () => {
            card.style.transform = 'translateY(-5px) scale(1.02)';
        });
        card.addEventListener('mouseleave', () => {
            card.style.transform = 'translateY(0) scale(1)';
        });
    });
    
    debugLog('Écouteurs initialisés', 'success');
}

/**
 * ═══════════════════════════════════════════════════════════════
 * MESSAGES DE LUA
 * ═══════════════════════════════════════════════════════════════
 */

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;
    
    debugLog(`Message: ${data.action}`, 'info');
    
    switch (data.action) {
        case 'open':
            openInterface(data.data?.animationDuration || 500);
            break;
        
        case 'close':
            closeInterface(data.data?.animationDuration || 400);
            break;
        
        case 'showNotification':
            // Notification depuis Lua
            showNotification(
                data.data.message,
                data.data.duration || 3000,
                data.data.type || 'info'
            );
            break;
    }
});

/**
 * ═══════════════════════════════════════════════════════════════
 * CALLBACKS NUI (pour Lua)
 * ═══════════════════════════════════════════════════════════════
 */

// Callback pour rejoindre Course Poursuite
window.addEventListener('NUICallback_joinCoursePoursuit', () => {
    debugLog('Callback: joinCoursePoursuit', 'info');
});

/**
 * ═══════════════════════════════════════════════════════════════
 * INITIALISATION
 * ═══════════════════════════════════════════════════════════════
 */

function init() {
    debugLog('═══════════════════════════════════════════════════════════════', 'info');
    debugLog('Init Scharman NUI...', 'info');
    debugLog('═══════════════════════════════════════════════════════════════', 'info');
    
    // Récupérer les éléments
    Elements.app = document.getElementById('app');
    Elements.closeBtn = document.getElementById('closeBtn');
    Elements.gameCards = Array.from(document.querySelectorAll('.game-card'));
    Elements.notificationContainer = document.getElementById('notification-container');
    
    if (!Elements.app || !Elements.closeBtn || !Elements.notificationContainer) {
        debugLog('Erreur: Éléments manquants!', 'error');
        return;
    }
    
    // Initialiser
    initEventListeners();
    Elements.app.classList.add('hidden');
    
    debugLog('═══════════════════════════════════════════════════════════════', 'info');
    debugLog('Scharman NUI initialisé!', 'success');
    debugLog('═══════════════════════════════════════════════════════════════', 'info');
}

// Animation shake
const shakeStyle = document.createElement('style');
shakeStyle.textContent = `
    @keyframes shake {
        0%, 100% { transform: translateX(0); }
        25% { transform: translateX(-10px); }
        75% { transform: translateX(10px); }
    }
`;
document.head.appendChild(shakeStyle);

// Démarrage
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}

// Debug
if (AppState.debugMode) {
    window.ScharmanDebug = {
        open: () => openInterface(),
        close: () => closeInterface(),
        notify: (msg, duration, type) => showNotification(msg, duration, type),
        post: post,
        state: AppState
    };
    debugLog('Mode debug activé', 'info');
}
