-- ==============================================================================
-- Initialisation de la Base de Données - CloudAsset Manager
-- Module I347 - Virtualisation d'une application avec conteneurs
-- ==============================================================================

CREATE TABLE IF NOT EXISTS assets (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ONLINE',
    location VARCHAR(50) NOT NULL DEFAULT 'Datacenter Lausanne',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insertion de données initiales pour la démonstration
INSERT INTO assets (name, category, ip_address, status, location) VALUES
('srv-docker-prod01', 'Host Docker', '192.168.10.15', 'ONLINE', 'Datacenter Lausanne'),
('db-postgres-cluster', 'Base de données', '192.168.10.20', 'ONLINE', 'Datacenter Lausanne'),
('proxy-nginx-edge', 'Reverse Proxy', '192.168.1.100', 'ONLINE', 'DMZ Genève'),
('srv-backup-storage', 'Stockage NAS', '192.168.10.80', 'ONLINE', 'Datacenter Yverdon'),
('vm-monitoring-portainer', 'Monitoring', '192.168.10.45', 'MAINTENANCE', 'Datacenter Yverdon')
ON CONFLICT DO NOTHING;
