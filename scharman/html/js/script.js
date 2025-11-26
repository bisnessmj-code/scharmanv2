const AppState = {
    isOpen: false,
    isAnimating: false,
    debugMode: true,
    countdownActive: false,
    vehicleLockActive: false,
    vehicleLockTimer: null
};

const Elements = {
    app: null,
    closeBtn: null,
    gameCards: [],
    notificationContainer: null,
    countdownContainer: null,
    countdownNumber: null,
    vehicleLockContainer: null,
    vehicleLockTimer: null,
    vehicleLockProgress: null
};

function debugLog(message, type = 'info') {
    if (!AppState.debugMode) return;
    const styles = {
        info: 'color: #00d4ff; font-weight: bold;',
        error: 'color: #ff006e; font-weight: bold;',
        success: 'color: #00ff88; font-weight: bold;'
    };
    console.log(`%c[Scharman NUI V2] ${message}`, styles[type] || styles.info);
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

/* ═══════════════════════════════════════════════════════════════
   ✅ DÉCOMPTE 3-2-1-GO
   ═══════════════════════════════════════════════════════════════ */

function showCountdown(number) {
    debugLog(`Affichage décompte: ${number}`, 'info');
    
    AppState.countdownActive = true;
    
    // Afficher le container
    Elements.countdownContainer.classList.remove('hidden');
    
    // Mettre à jour le nombre
    Elements.countdownNumber.textContent = number;
    
    // Ajouter classe spéciale pour GO!
    if (number === 'GO!') {
        Elements.countdownNumber.classList.add('go');
    } else {
        Elements.countdownNumber.classList.remove('go');
    }
    
    // Forcer reflow pour animation
    Elements.countdownNumber.style.animation = 'none';
    void Elements.countdownNumber.offsetWidth;
    Elements.countdownNumber.style.animation = '';
}

function hideCountdown() {
    debugLog('Masquage décompte', 'info');
    
    AppState.countdownActive = false;
    Elements.countdownContainer.classList.add('hidden');
    Elements.countdownNumber.classList.remove('go');
}

/* ═══════════════════════════════════════════════════════════════
   ✅ MESSAGE BLOCAGE VÉHICULE
   ═══════════════════════════════════════════════════════════════ */

function showVehicleLock(duration = 30000) {
    debugLog(`Affichage blocage véhicule (${duration}ms)`, 'info');
    
    AppState.vehicleLockActive = true;
    
    // Afficher le container
    Elements.vehicleLockContainer.classList.remove('hidden');
    
    // Initialiser la barre de progression à 100%
    Elements.vehicleLockProgress.style.width = '100%';
    
    // Temps restant en secondes
    let timeLeft = duration / 1000;
    
    // Mettre à jour le timer
    Elements.vehicleLockTimer.textContent = `${timeLeft}s`;
    
    // Démarrer le compte à rebours
    const startTime = Date.now();
    
    AppState.vehicleLockTimer = setInterval(() => {
        const elapsed = Date.now() - startTime;
        const remaining = Math.max(0, duration - elapsed);
        timeLeft = Math.ceil(remaining / 1000);
        
        // Mettre à jour le texte
        Elements.vehicleLockTimer.textContent = `${timeLeft}s`;
        
        // Mettre à jour la barre de progression
        const progress = (remaining / duration) * 100;
        Elements.vehicleLockProgress.style.width = `${progress}%`;
        
        // Si terminé, masquer
        if (remaining <= 0) {
            hideVehicleLock();
        }
    }, 100);
}

function hideVehicleLock() {
    debugLog('Masquage blocage véhicule', 'info');
    
    if (AppState.vehicleLockTimer) {
        clearInterval(AppState.vehicleLockTimer);
        AppState.vehicleLockTimer = null;
    }
    
    AppState.vehicleLockActive = false;
    Elements.vehicleLockContainer.classList.add('hidden');
}

/* ═══════════════════════════════════════════════════════════════
   GESTION DES ÉVÉNEMENTS
   ═══════════════════════════════════════════════════════════════ */

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

/* ═══════════════════════════════════════════════════════════════
   RÉCEPTION DES MESSAGES DE LUA
   ═══════════════════════════════════════════════════════════════ */

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
        
        // ✅ NOUVEAU: Décompte
        case 'showCountdown':
            showCountdown(data.data.number);
            break;
        case 'hideCountdown':
            hideCountdown();
            break;
        
        // ✅ NOUVEAU: Blocage véhicule
        case 'showVehicleLock':
            showVehicleLock(data.data.duration || 30000);
            break;
        case 'hideVehicleLock':
            hideVehicleLock();
            break;
        case 'showDeathScreen':
            showDeathScreen();
            break;
        case 'hideDeathScreen':
            hideDeathScreen();
            break;
    }
});

/* ═══════════════════════════════════════════════════════════════
   💀 ÉCRAN DE MORT
   ═══════════════════════════════════════════════════════════════ */

function showDeathScreen() {
    debugLog('Affichage écran de mort', 'error');
    const deathScreen = document.getElementById('death-screen-container');
    if (deathScreen) {
        deathScreen.classList.remove('hidden');
    }
}

function hideDeathScreen() {
    debugLog('Masquage écran de mort');
    const deathScreen = document.getElementById('death-screen-container');
    if (deathScreen) {
        deathScreen.classList.add('hidden');
    }
}

/* ═══════════════════════════════════════════════════════════════
   INITIALISATION
   ═══════════════════════════════════════════════════════════════ */

function init() {
    debugLog('═══════════════════════════════════════════════════════════════', 'info');
    debugLog('Init Scharman NUI V2.0...', 'info');
    debugLog('═══════════════════════════════════════════════════════════════', 'info');
    
    Elements.app = document.getElementById('app');
    Elements.closeBtn = document.getElementById('closeBtn');
    Elements.gameCards = Array.from(document.querySelectorAll('.game-card'));
    Elements.notificationContainer = document.getElementById('notification-container');
    
    // ✅ NOUVEAUX ÉLÉMENTS
    Elements.countdownContainer = document.getElementById('countdown-container');
    Elements.countdownNumber = Elements.countdownContainer?.querySelector('.countdown-number');
    Elements.vehicleLockContainer = document.getElementById('vehicle-lock-container');
    Elements.vehicleLockTimer = document.getElementById('vehicle-lock-timer');
    Elements.vehicleLockProgress = document.getElementById('vehicle-lock-progress');
    
    if (!Elements.app || !Elements.closeBtn || !Elements.notificationContainer) {
        debugLog('Erreur: Éléments manquants!', 'error');
        return;
    }
    
    if (!Elements.countdownContainer || !Elements.countdownNumber) {
        debugLog('Erreur: Éléments décompte manquants!', 'error');
    }
    
    if (!Elements.vehicleLockContainer || !Elements.vehicleLockTimer || !Elements.vehicleLockProgress) {
        debugLog('Erreur: Éléments blocage véhicule manquants!', 'error');
    }
    
    initEventListeners();
    Elements.app.classList.add('hidden');
    
    debugLog('═══════════════════════════════════════════════════════════════', 'info');
    debugLog('Scharman NUI V2.0 initialisé!', 'success');
    debugLog('- Décompte 3-2-1-GO: OK', 'success');
    debugLog('- Blocage véhicule: OK', 'success');
    debugLog('═══════════════════════════════════════════════════════════════', 'info');
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}
