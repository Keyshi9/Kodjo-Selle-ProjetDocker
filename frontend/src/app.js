const API_BASE = '/api';

// Éléments du DOM
const backendStatusDot = document.getElementById('backend-status-dot');
const dbStatusDot = document.getElementById('db-status-dot');
const backendVersion = document.getElementById('backend-version');
const statTotal = document.getElementById('stat-total');
const statOnline = document.getElementById('stat-online');
const statMaint = document.getElementById('stat-maint');
const statOffline = document.getElementById('stat-offline');
const assetsTbody = document.getElementById('assets-tbody');
const addAssetForm = document.getElementById('add-asset-form');
const formFeedback = document.getElementById('form-feedback');
const btnRefresh = document.getElementById('btn-refresh');

// 1. Vérification de santé (Healthcheck)
async function checkHealth() {
    try {
        const res = await fetch(`${API_BASE}/health`);
        const data = await res.json();
        
        if (res.ok && data.status === 'healthy') {
            backendStatusDot.className = 'service-indicator online';
            dbStatusDot.className = data.database_connected ? 'service-indicator online' : 'service-indicator offline';
        } else {
            backendStatusDot.className = 'service-indicator online';
            dbStatusDot.className = 'service-indicator offline';
        }
    } catch (err) {
        backendStatusDot.className = 'service-indicator offline';
        dbStatusDot.className = 'service-indicator offline';
    }
}

// 2. Récupérer les statistiques
async function loadStats() {
    try {
        const res = await fetch(`${API_BASE}/stats`);
        if (!res.ok) return;
        const json = await res.json();
        if (json.success) {
            statTotal.textContent = json.total_assets;
            statOnline.textContent = json.status_breakdown.ONLINE || 0;
            statMaint.textContent = json.status_breakdown.MAINTENANCE || 0;
            statOffline.textContent = json.status_breakdown.OFFLINE || 0;
        }
    } catch (err) {
        console.error('Erreur chargement stats:', err);
    }
}

// 3. Récupérer la liste des équipements (Assets)
async function loadAssets() {
    try {
        const res = await fetch(`${API_BASE}/assets`);
        if (!res.ok) throw new Error('Impossible de charger les données');
        const json = await res.json();
        
        if (!json.success || !json.data || json.data.length === 0) {
            assetsTbody.innerHTML = `<tr><td colspan="7" class="text-center">Aucun équipement enregistré dans la base de données.</td></tr>`;
            return;
        }

        assetsTbody.innerHTML = json.data.map(item => `
            <tr>
                <td>#${item.id}</td>
                <td><strong>${escapeHtml(item.name)}</strong></td>
                <td>${escapeHtml(item.category)}</td>
                <td><code>${escapeHtml(item.ip_address)}</code></td>
                <td><span class="badge-status ${escapeHtml(item.status)}">${escapeHtml(item.status)}</span></td>
                <td>${escapeHtml(item.location)}</td>
                <td>
                    <button class="btn-danger-sm" onclick="deleteAsset(${item.id})">Supprimer</button>
                </td>
            </tr>
        `).join('');
    } catch (err) {
        assetsTbody.innerHTML = `<tr><td colspan="7" class="text-center text-danger">Erreur de connexion à l'API (${err.message})</td></tr>`;
    }
}

// 4. Ajouter un équipement
addAssetForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    formFeedback.textContent = 'Enregistrement en cours...';
    formFeedback.className = 'form-feedback';

    const payload = {
        name: document.getElementById('asset-name').value,
        category: document.getElementById('asset-category').value,
        ip_address: document.getElementById('asset-ip').value,
        status: document.getElementById('asset-status').value,
        location: document.getElementById('asset-location').value
    };

    try {
        const res = await fetch(`${API_BASE}/assets`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        const json = await res.json();

        if (res.ok && json.success) {
            formFeedback.textContent = '✅ Équipement ajouté avec succès !';
            formFeedback.className = 'form-feedback success';
            addAssetForm.reset();
            document.getElementById('asset-location').value = 'Datacenter Lausanne';
            await loadAssets();
            await loadStats();
            setTimeout(() => { formFeedback.textContent = ''; }, 3000);
        } else {
            formFeedback.textContent = `❌ Erreur : ${json.error || 'Erreur serveur'}`;
            formFeedback.className = 'form-feedback error';
        }
    } catch (err) {
        formFeedback.textContent = `❌ Impossible de joindre l'API : ${err.message}`;
        formFeedback.className = 'form-feedback error';
    }
});

// 5. Supprimer un équipement
window.deleteAsset = async function(id) {
    if (!confirm(`Confirmer la suppression de l'équipement #${id} ?`)) return;

    try {
        const res = await fetch(`${API_BASE}/assets/${id}`, { method: 'DELETE' });
        const json = await res.json();
        if (res.ok && json.success) {
            await loadAssets();
            await loadStats();
        } else {
            alert(`Erreur : ${json.error}`);
        }
    } catch (err) {
        alert(`Erreur réseau : ${err.message}`);
    }
};

// Utilitaire pour éviter les failles XSS
function escapeHtml(str) {
    if (!str) return '';
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

// Bouton rafraîchir
btnRefresh.addEventListener('click', () => {
    checkHealth();
    loadStats();
    loadAssets();
});

// Initialisation et boucle de mise à jour
function init() {
    checkHealth();
    loadStats();
    loadAssets();
    setInterval(checkHealth, 10000);
}

document.addEventListener('DOMContentLoaded', init);
