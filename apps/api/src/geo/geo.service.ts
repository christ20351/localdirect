import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StatutVille } from '@prisma/client';

@Injectable()
export class GeoService implements OnModuleInit {
  private readonly logger = new Logger(GeoService.name);

  constructor(private prisma: PrismaService) {}

  // Exécuté automatiquement au démarrage du module pour vérifier et alimenter les villes et quartiers
  async onModuleInit() {
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
        parametres: {
          fraisVisite: 2000,
          commissionAgentVisite: 1400,
          commissionPlateformeVisite: 600,
        },
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
        parametres: {
          fraisVisite: 2000,
          commissionAgentVisite: 1400,
          commissionPlateformeVisite: 600,
        },
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
