import { Injectable, NotFoundException, OnModuleInit, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FiltreAnnonceDto } from './dtos/filtre-annonce.dto';
import { CreerBienDto } from './dtos/creer-bien.dto';
import { StatutBien, StatutVille } from '@prisma/client';

@Injectable()
export class AnnoncesService implements OnModuleInit {
  private readonly logger = new Logger(AnnoncesService.name);

  constructor(private prisma: PrismaService) {}

  // Initialisation automatique des annonces de démonstration au démarrage
  async onModuleInit() {
    await this.seedDemoAnnonces();
  }

  /// 🔍 Rechercher et filtrer les annonces (Catalogue public)
  async getAnnonces(filtre: FiltreAnnonceDto) {
    const page = parseInt(filtre.page || '1', 10);
    const limit = parseInt(filtre.limit || '10', 10);
    const skip = (page - 1) * limit;

    // Construction dynamique de la clause WHERE Prisma
    const whereClause: any = {
      bien: {
        statut: StatutBien.DISPONIBLE,
      },
    };

    if (filtre.ville) {
      whereClause.bien.ville = { slug: filtre.ville };
    }

    if (filtre.quartier) {
      whereClause.bien.quartier = { slug: filtre.quartier };
    }

    if (filtre.type) {
      whereClause.bien.type = filtre.type;
    }

    if (filtre.meuble !== undefined) {
      whereClause.bien.meuble = filtre.meuble === 'true';
    }

    if (filtre.loyerMin || filtre.loyerMax) {
      whereClause.loyerMensuel = {};
      if (filtre.loyerMin) whereClause.loyerMensuel.gte = BigInt(filtre.loyerMin);
      if (filtre.loyerMax) whereClause.loyerMensuel.lte = BigInt(filtre.loyerMax);
    }

    if (filtre.avanceMax) {
      whereClause.avanceMois = { lte: parseInt(filtre.avanceMax, 10) };
    }

    // Execution de la requête Prisma avec comptage total pour la pagination
    const [total, annonces] = await Promise.all([
      this.prisma.annonce.count({ where: whereClause }),
      this.prisma.annonce.findMany({
        where: whereClause,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          bien: {
            include: {
              ville: true,
              quartier: true,
              pointRepere: true,
              medias: true,
            },
          },
        },
      }),
    ]);

    // Conversion des BigInt (loyers XAF) en Number pour la sérialisation JSON
    const dataFormatted = annonces.map((item) => this.formatAnnonceResponse(item));

    return {
      data: dataFormatted,
      meta: {
        total,
        page,
        limit,
        pagesTotal: Math.ceil(total / limit),
      },
    };
  }

  /// 🏠 Récupérer le détail d'une annonce avec calcul de position floue (~200m)
  async getAnnonceById(id: string) {
    const item = await this.prisma.annonce.findUnique({
      where: { id },
      include: {
        bien: {
          include: {
            ville: true,
            quartier: true,
            pointRepere: true,
            medias: true,
          },
        },
      },
    });

    if (!item) {
      throw new NotFoundException(`Annonce introuvable pour l'ID : ${id}`);
    }

    // Incrémentation du compteur de vues
    await this.prisma.annonce.update({
      where: { id },
      data: { nbVues: { increment: 1 } },
    });

    return this.formatAnnonceResponse(item);
  }

  /// ➕ Créer un bien et son annonce associée par un Agent / Bailleur
  async creerBienEtAnnonce(utilisateurId: string, dto: CreerBienDto) {
    const reference = `DLA-BM-${Date.now().toString().substring(7)}`;

    // Calcul de la position floue (~200m) pour masquer la géolocalisation exacte avant la visite
    const latitudeFloue = dto.latitude ? dto.latitude + (Math.random() - 0.5) * 0.003 : undefined;
    const longitudeFloue = dto.longitude ? dto.longitude + (Math.random() - 0.5) * 0.003 : undefined;

    const bien = await this.prisma.bien.create({
      data: {
        reference,
        creeParId: utilisateurId,
        villeId: dto.villeId,
        quartierId: dto.quartierId,
        pointRepereId: dto.pointRepereId,
        indicationAcces: dto.indicationAcces,
        type: dto.type,
        meuble: dto.meuble || false,
        equipements: dto.equipements || [],
        latitude: dto.latitude,
        longitude: dto.longitude,
        latitudeFloue,
        longitudeFloue,
        statut: StatutBien.EN_VERIFICATION, // Le bien doit être vérifié par le Staff avant publication
        annonces: {
          create: {
            titre: dto.titre,
            description: dto.description,
            loyerMensuel: BigInt(dto.loyerMensuel),
            chargesMensuelles: BigInt(dto.chargesMensuelles || 0),
            avanceMois: dto.avanceMois || 2,
            cautionMois: dto.cautionMois || 1,
            publieeLe: new Date(),
          },
        },
        medias: {
          create: (dto.photos || []).map((url, index) => ({
            storageKey: url,
            ordre: index,
          })),
        },
      },
      include: {
        annonces: true,
      },
    });

    return {
      message: 'Bien créé avec succès ! Il est actuellement en cours de vérification par l\'équipe modération.',
      bienId: bien.id,
      annonceId: bien.annonces[0]?.id,
    };
  }

  /// 🛠️ Méthode utilitaire de mise en forme des BigInt pour l'API REST
  private formatAnnonceResponse(item: any) {
    const loyerMensuel = Number(item.loyerMensuel);
    const chargesMensuelles = Number(item.chargesMensuelles);
    const avanceMois = item.avanceMois;
    const cautionMois = item.cautionMois;

    const montantAvance = loyerMensuel * avanceMois;
    const montantCaution = loyerMensuel * cautionMois;
    const totalInitial = montantAvance + montantCaution;

    return {
      id: item.id,
      titre: item.titre,
      description: item.description,
      finances: {
        loyerMensuelXAF: loyerMensuel,
        chargesMensuellesXAF: chargesMensuelles,
        chargesIncluses: item.chargesIncluses,
        avanceMois,
        montantAvanceXAF: montantAvance,
        cautionMois,
        montantCautionXAF: montantCaution,
        totalInitialEntreeXAF: totalInitial,
        fraisVisiteXAF: 2000,
      },
      bien: {
        id: item.bien.id,
        reference: item.bien.reference,
        type: item.bien.type,
        meuble: item.bien.meuble,
        equipements: item.bien.equipements,
        ville: item.bien.ville?.nom,
        quartier: item.bien.quartier?.nom,
        pointRepere: item.bien.pointRepere?.nom,
        // Envoi uniquement de la position floue publique (~200m)
        latitudeFloue: item.bien.latitudeFloue,
        longitudeFloue: item.bien.longitudeFloue,
        photos: item.bien.medias.map((m: any) => m.storageKey),
      },
      nbVues: item.nbVues,
      createdAt: item.createdAt,
    };
  }

  /// 🌱 Seed automatique des annonces de démonstration
  private async seedDemoAnnonces() {
    const countAnnonces = await this.prisma.annonce.count();
    if (countAnnonces > 0) return;

    this.logger.log('🌱 Alimentation des annonces de démonstration (Bonamoussadi & Biyem-Assi)...');

    const bonaQuartier = await this.prisma.quartier.findFirst({ where: { slug: 'bonamoussadi' } });
    const userAdmin = await this.prisma.utilisateur.findFirst();

    if (!bonaQuartier || !userAdmin) return;

    const repereCamico = await this.prisma.pointRepere.findFirst({ where: { quartierId: bonaQuartier.id } });

    await this.prisma.bien.create({
      data: {
        reference: 'DLA-BM-00123',
        creeParId: userAdmin.id,
        villeId: bonaQuartier.villeId,
        quartierId: bonaQuartier.id,
        pointRepereId: repereCamico?.id,
        indicationAcces: 'À 2 min du Carrefour Camico, portail vert',
        type: 'STUDIO',
        meuble: true,
        equipements: ['EAU_COURANTE', 'GROUPE_ELECTROGENE', 'CLIMATISATION'],
        latitude: 4.0812,
        longitude: 9.7423,
        latitudeFloue: 4.0820,
        longitudeFloue: 9.7430,
        statut: StatutBien.DISPONIBLE,
        annonces: {
          create: {
            titre: 'Studio Moderne Climatisé avec Balcon',
            description: 'Magnifique studio moderne entièrement carrelé avec compteur ENEO individuel et eau courante.',
            loyerMensuel: BigInt(65000),
            chargesMensuelles: BigInt(5000),
            chargesIncluses: true,
            avanceMois: 3,
            cautionMois: 1,
            publieeLe: new Date(),
          },
        },
        medias: {
          create: [
            { storageKey: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80', ordre: 0 },
            { storageKey: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=800&q=80', ordre: 1 },
          ],
        },
      },
    });

    this.logger.log('✅ Annonces de démonstration créées !');
  }
}
