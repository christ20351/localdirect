import { Injectable, OnModuleInit, Logger, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StatutVille } from '@prisma/client';
import { CreerVilleDto } from './dtos/creer-ville.dto';
import { ModifierVilleDto } from './dtos/modifier-ville.dto';
import { CreerQuartierDto } from './dtos/creer-quartier.dto';
import { ModifierQuartierDto } from './dtos/modifier-quartier.dto';
import { AuditService } from '../audit/audit.service';

@Injectable()
export class GeoService implements OnModuleInit {
  private readonly logger = new Logger(GeoService.name);

  constructor(
    private prisma: PrismaService,
    private auditService: AuditService,
  ) {}

  // Amorçage du référentiel géographique (villes et quartiers de démonstration).
  // Opt-in explicite : en production la base doit rester vide de données de
  // démonstration. Poser SEED_DEMO_DATA=true pour le réactiver en local.
  async onModuleInit() {
    if (process.env.SEED_DEMO_DATA !== 'true') return;
    await this.seedInitialGeoData();
  }

  /// 🏙️ Récupérer la liste des villes (ex: Douala, Yaoundé)
  async getVilles(statut: StatutVille = StatutVille.OUVERTE) {
    return this.prisma.ville.findMany({
      where: { statut },
      orderBy: { nom: 'asc' },
    });
  }

  /// 📍 Récupérer les quartiers d'une ville spécifique par son slug (ex: "douala")
  async getQuartiersParVille(villeSlug: string) {
    return this.prisma.quartier.findMany({
      where: {
        ville: { slug: villeSlug },
        actif: true,
      },
      include: {
        reperes: true,
      },
      orderBy: { nom: 'asc' },
    });
  }

  /// 📌 Récupérer les points de repère réels d'un quartier (ex: Carrefour Kotto, Station Total Makèpè)
  async getReperesParQuartier(quartierId: string) {
    return this.prisma.pointRepere.findMany({
      where: { quartierId },
      orderBy: { nom: 'asc' },
    });
  }

  // =========================================================
  // 🛡️ PILOTAGE MULTI-VILLES — Réservé ADMIN (ouverture/fermeture de villes,
  // gestion des quartiers). Décisions stratégiques, pas de simple modération.
  // =========================================================

  /// ➕ Créer une nouvelle ville — ADMIN
  async creerVille(adminId: string, dto: CreerVilleDto) {
    const existante = await this.prisma.ville.findUnique({ where: { slug: dto.slug } });
    if (existante) {
      throw new ConflictException(`Une ville avec le slug "${dto.slug}" existe déjà.`);
    }

    const ville = await this.prisma.ville.create({
      data: {
        nom: dto.nom,
        region: dto.region,
        slug: dto.slug,
        statut: dto.statut || StatutVille.FERMEE,
        latitude: dto.latitude,
        longitude: dto.longitude,
      },
    });

    await this.auditService.log(adminId, 'VILLE_CREEE', 'Ville', ville.id, undefined, ville);
    return ville;
  }

  /// ✏️ Modifier une ville (nom, région, slug, statut d'ouverture, coordonnées) — ADMIN
  async modifierVille(adminId: string, villeId: string, dto: ModifierVilleDto) {
    const avant = await this.prisma.ville.findUnique({ where: { id: villeId } });
    if (!avant) {
      throw new NotFoundException(`Ville introuvable pour l'ID : ${villeId}`);
    }

    const ville = await this.prisma.ville.update({
      where: { id: villeId },
      data: {
        ...(dto.nom !== undefined ? { nom: dto.nom } : {}),
        ...(dto.region !== undefined ? { region: dto.region } : {}),
        ...(dto.slug !== undefined ? { slug: dto.slug } : {}),
        ...(dto.statut !== undefined ? { statut: dto.statut } : {}),
        ...(dto.latitude !== undefined ? { latitude: dto.latitude } : {}),
        ...(dto.longitude !== undefined ? { longitude: dto.longitude } : {}),
      },
    });

    await this.auditService.log(adminId, 'VILLE_MODIFIEE', 'Ville', villeId, avant, ville);
    return ville;
  }

  /// ➕ Ajouter un quartier à une ville — ADMIN
  async creerQuartier(adminId: string, villeId: string, dto: CreerQuartierDto) {
    const ville = await this.prisma.ville.findUnique({ where: { id: villeId } });
    if (!ville) {
      throw new NotFoundException(`Ville introuvable pour l'ID : ${villeId}`);
    }

    const slug = dto.slug || dto.nom.toLowerCase().trim().replaceAll(' ', '-');
    const existant = await this.prisma.quartier.findUnique({ where: { villeId_slug: { villeId, slug } } });
    if (existant) {
      throw new ConflictException(`Un quartier avec le slug "${slug}" existe déjà pour cette ville.`);
    }

    const quartier = await this.prisma.quartier.create({
      data: {
        villeId,
        nom: dto.nom,
        slug,
        aliases: dto.aliases || [],
      },
    });

    await this.auditService.log(adminId, 'QUARTIER_CREE', 'Quartier', quartier.id, undefined, quartier);
    return quartier;
  }

  /// ✏️ Modifier un quartier — ADMIN
  async modifierQuartier(adminId: string, quartierId: string, dto: ModifierQuartierDto) {
    const avant = await this.prisma.quartier.findUnique({ where: { id: quartierId } });
    if (!avant) {
      throw new NotFoundException(`Quartier introuvable pour l'ID : ${quartierId}`);
    }

    const quartier = await this.prisma.quartier.update({
      where: { id: quartierId },
      data: {
        ...(dto.nom !== undefined ? { nom: dto.nom } : {}),
        ...(dto.slug !== undefined ? { slug: dto.slug } : {}),
        ...(dto.aliases !== undefined ? { aliases: dto.aliases } : {}),
        ...(dto.actif !== undefined ? { actif: dto.actif } : {}),
      },
    });

    await this.auditService.log(adminId, 'QUARTIER_MODIFIE', 'Quartier', quartierId, avant, quartier);
    return quartier;
  }

  /// 🌱 Méthode de seed automatique des villes et quartiers de Douala & Yaoundé
  private async seedInitialGeoData() {
    const countVilles = await this.prisma.ville.count();
    if (countVilles > 0) return; // Si la BDD contient déjà des villes, on ne réinjecte pas

    this.logger.log('🌱 Alimentation initiale des données géographiques (Douala & Yaoundé)...');

    // 1. Création de Douala
    const douala = await this.prisma.ville.create({
      data: {
        nom: 'Douala',
        region: 'Littoral',
        slug: 'douala',
        statut: StatutVille.OUVERTE,
        latitude: 4.0511,
        longitude: 9.7679,
        parametres: {},
      },
    });

    // Quartiers & Repères de Douala
    const quartiersDouala = [
      {
        nom: 'Bonamoussadi',
        slug: 'bonamoussadi',
        aliases: ['Bona', 'Bonamoussadi Denis'],
        reperes: ['Carrefour Camico', 'Rond-Point Santa Barbara', 'Carrefour Kotto'],
      },
      {
        nom: 'Makèpè',
        slug: 'makepe',
        aliases: ['Makepe BM', 'Makepe Missoke'],
        reperes: ['Station Total Makèpè', 'Carrefour BM', 'Bloc L'],
      },
      {
        nom: 'Kotto',
        slug: 'kotto',
        aliases: ['Kotto Badengue', 'Kotto Bloc'],
        reperes: ['Carrefour Kotto', 'Entrée Chefferie Kotto'],
      },
      {
        nom: 'Logpom',
        slug: 'logpom',
        aliases: ['Logpom Bassong', 'Logpom Karata'],
        reperes: ['Carrefour Bassong', 'Station Tradex Logpom'],
      },
    ];

    for (const q of quartiersDouala) {
      await this.prisma.quartier.create({
        data: {
          villeId: douala.id,
          nom: q.nom,
          slug: q.slug,
          aliases: q.aliases,
          reperes: {
            create: q.reperes.map((nomRepere) => ({
              nom: nomRepere,
              latitude: 4.08,
              longitude: 9.75,
            })),
          },
        },
      });
    }

    // 2. Création de Yaoundé
    const yaounde = await this.prisma.ville.create({
      data: {
        nom: 'Yaoundé',
        region: 'Centre',
        slug: 'yaounde',
        statut: StatutVille.OUVERTE,
        latitude: 3.8480,
        longitude: 11.5021,
        parametres: {},
      },
    });

    // Quartiers & Repères de Yaoundé
    const quartiersYaounde = [
      {
        nom: 'Bastos',
        slug: 'bastos',
        aliases: ['Bastos Ambassade', 'Golf'],
        reperes: ['Rond-Point Bastos', 'Ambassade des USA'],
      },
      {
        nom: 'Biyem-Assi',
        slug: 'biyem-assi',
        aliases: ['Biyem Assi', 'Acacias', 'Mendong'],
        reperes: ['Carrefour Acacias', 'Rond-Point Express'],
      },
    ];

    for (const q of quartiersYaounde) {
      await this.prisma.quartier.create({
        data: {
          villeId: yaounde.id,
          nom: q.nom,
          slug: q.slug,
          aliases: q.aliases,
          reperes: {
            create: q.reperes.map((nomRepere) => ({
              nom: nomRepere,
              latitude: 3.85,
              longitude: 11.50,
            })),
          },
        },
      });
    }

    this.logger.log('✅ Base géographique initialisée avec succès !');
  }
}
