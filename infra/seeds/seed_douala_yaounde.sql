-- =========================================================
-- Seeds Géographiques : Douala et Yaoundé
-- =========================================================

-- Villes
INSERT INTO ville (id, nom, region, slug, statut, parametres) VALUES
('11111111-1111-1111-1111-111111111111', 'Douala', 'Littoral', 'douala', 'OUVERTE', '{"frais_visite": 2000, "commission_agent_visite": 1400, "commission_plateforme_visite": 600}'),
('22222222-2222-2222-2222-222222222222', 'Yaoundé', 'Centre', 'yaounde', 'OUVERTE', '{"frais_visite": 2000, "commission_agent_visite": 1400, "commission_plateforme_visite": 600}');

-- Quartiers Douala
INSERT INTO quartier (id, ville_id, nom, slug, aliases) VALUES
('d1111111-0001-0000-0000-000000000000', '11111111-1111-1111-1111-111111111111', 'Bonamoussadi', 'bonamoussadi', '{"Bona", "Bonamoussadi Denis"}'),
('d1111111-0002-0000-0000-000000000000', '11111111-1111-1111-1111-111111111111', 'Makèpè', 'makepe', '{"Makepe", "Makepe BM", "Makepe Missoke"}'),
('d1111111-0003-0000-0000-000000000000', '11111111-1111-1111-1111-111111111111', 'Kotto', 'kotto', '{"Kotto Badengue", "Kotto Bloc"}'),
('d1111111-0004-0000-0000-000000000000', '11111111-1111-1111-1111-111111111111', 'Akwa', 'akwa', '{"Akwa Nord", "Centre Ville"}'),
('d1111111-0005-0000-0000-000000000000', '11111111-1111-1111-1111-111111111111', 'Logpom', 'logpom', '{"Logpom Bassong", "Logpom Karata"}'),
('d1111111-0006-0000-0000-000000000000', '11111111-1111-1111-1111-111111111111', 'Bonapriso', 'bonapriso', '{"Bonapriso Hydrocarbures"}');

-- Points de Repère Douala
INSERT INTO point_repere (quartier_id, nom, position) VALUES
('d1111111-0001-0000-0000-000000000000', 'Carrefour Camico', ST_SetSRID(ST_MakePoint(9.7423, 4.0812), 4326)),
('d1111111-0001-0000-0000-000000000000', 'Rond-Point Santa Barbara', ST_SetSRID(ST_MakePoint(9.7450, 4.0835), 4326)),
('d1111111-0002-0000-0000-000000000000', 'Station Total Makèpè', ST_SetSRID(ST_MakePoint(9.7510, 4.0750), 4326)),
('d1111111-0003-0000-0000-000000000000', 'Carrefour Kotto', ST_SetSRID(ST_MakePoint(9.7600, 4.0900), 4326));

-- Quartiers Yaoundé
INSERT INTO quartier (id, ville_id, nom, slug, aliases) VALUES
('y2222222-0001-0000-0000-000000000000', '22222222-2222-2222-2222-222222222222', 'Bastos', 'bastos', '{"Bastos Ambassade", "Golf"}'),
('y2222222-0002-0000-0000-000000000000', '22222222-2222-2222-2222-222222222222', 'Biyem-Assi', 'biyem-assi', '{"Biyem Assi", "Acacias", "Mendong"}'),
('y2222222-0003-0000-0000-000000000000', '22222222-2222-2222-2222-222222222222', 'Ngoa-Ekellé', 'ngoa-ekelle', '{"Ngoa Ekelle", "Château"}');

-- Points de Repère Yaoundé
INSERT INTO point_repere (quartier_id, nom, position) VALUES
('y2222222-0001-0000-0000-000000000000', 'Rond-Point Bastos', ST_SetSRID(ST_MakePoint(11.5175, 3.8860), 4326)),
('y2222222-0002-0000-0000-000000000000', 'Carrefour Acacias', ST_SetSRID(ST_MakePoint(11.4920, 3.8410), 4326));
