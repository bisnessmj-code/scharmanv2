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

function debugLog(message, type = 'info') {
    if (!AppState.debugMode) return;
    const styles = {
        info: 'color: #00d4ff; font-weight: bold;',
        error: 'color: #ff006e; font-weight: bold;',
        success: 'color: #00ff88; font-weight: bold;'
    };
    console.log(`%c[Scharman NUI] ${message}`, styles[type] || styles.info);
}

function post(action, data = {}) {
    fetch(`https://scharman/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).then(resp => resp.json()).then(resp => {
        debugLog(`✓ Callback ${action} réussi`, 'success');
    }).catch(error => {
        debugLog(`✗ Callback ${action} échoué: ${error}`, 'error');
    });
}

function showNotification(message, duration = 3000, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `game-notification ${type}`;
    notification.textContent = message;
    Elements.notificationContainer.appendChild(notification);
    
    debugLog(`Notification: ${message} (${type})`, type === 'error' ? 'error' : 'info');
    
    setTimeout(() => {
        notification.classList.add('closing');
        setTimeout(() => {
            if (notification.parentElement) {
                notification.parentElement.removeChild(notification);
            }
        }, 300);
    }, duration);
}

function openInterface(animationDuration = 500) {
    if (AppState.isOpen || AppState.isAnimating) return;
    debugLog('Ouverture de l\'interface...', 'info');
    AppState.isAnimating = true;
    Elements.app.classList.remove('hidden');
    setTimeout(() => {
        AppState.isOpen = true;
        AppState.isAnimating = false;
        debugLog('Interface ouverte', 'success');
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
        post('close');
    }, animationDuration);
}

function startCoursePoursuiteMode() {
    debugLog('Lancement du mode Course Poursuite', 'info');
    showNotification('🏁 Recherche d\'une partie...', 2000, 'info');
    closeInterface();
    setTimeout(() => {
        post('joinCoursePoursuit', {});
    }, 500);
}

function handleCardClick(cardElement, index) {
    debugLog(`Clic sur la carte ${index}`, 'info');
    const gameMode = cardElement.getAttribute('data-mode');
    const button = cardElement.querySelector('.btn-primary');
    
    if (button && button.disabled) {
        debugLog('Mode désactivé', 'warning');
        showNotification('❌ Ce mode de jeu n\'est pas encore disponible', 2000, 'warning');
        return;
    }
    
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

function initEventListeners() {
    debugLog('Initialisation des écouteurs...', 'info');
    
    Elements.closeBtn.addEventListener('click', () => {
        debugLog('Clic fermeture', 'info');
        closeInterface();
    });
    
    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && AppState.isOpen) {
            debugLog('ESC détecté', 'info');
            closeInterface();
        }
    });
    
    document.addEventListener('contextmenu', (e) => e.preventDefault());
    
    Elements.gameCards.forEach((card, index) => {
        card.addEventListener('click', () => handleCardClick(card, index));
        const button = card.querySelector('.btn-primary');
        if (button) {
            button.addEventListener('click', (e) => {
                e.stopPropagation();
                if (!button.disabled) {
                    handleCardClick(card, index);
                }
            });
        }
    });
    
    debugLog('Écouteurs initialisés', 'success');
}

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
            showNotification(data.data.message, data.data.duration || 3000, data.data.type || 'info');
            break;
    }
});

function init() {
    debugLog('═══════════════════════════════════════════════════════════════', 'info');
    debugLog('Init Scharman NUI...', 'info');
    debugLog('═══════════════════════════════════════════════════════════════', 'info');
    
    Elements.app = document.getElementById('app');
    Elements.closeBtn = document.getElementById('closeBtn');
    Elements.gameCards = Array.from(document.querySelectorAll('.game-card'));
    Elements.notificationContainer = document.getElementById('notification-container');
    
    if (!Elements.app || !Elements.closeBtn || !Elements.notificationContainer) {
        debugLog('Erreur: Éléments manquants!', 'error');
        return;
    }
    
    initEventListeners();
    Elements.app.classList.add('hidden');
    
    debugLog('═══════════════════════════════════════════════════════════════', 'info');
    debugLog('Scharman NUI initialisé!', 'success');
    debugLog('═══════════════════════════════════════════════════════════════', 'info');
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}
