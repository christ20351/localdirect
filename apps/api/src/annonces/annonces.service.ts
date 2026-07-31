import { Injectable, NotFoundException, OnModuleInit, Logger, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FiltreAnnonceDto } from './dtos/filtre-annonce.dto';
import { CreerBienDto } from './dtos/creer-bien.dto';
import { ModifierBienDto } from './dtos/modifier-bien.dto';
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

    if (filtre.nbPieces) {
      whereClause.bien.nbPieces = { gte: parseInt(filtre.nbPieces, 10) };
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

    // Résolution automatique des identifiants géographiques (Ville & Quartier)
    let targetVilleId = dto.villeId;
    if (!targetVilleId) {
      const villeSlug = (dto.villeSlug || 'douala').toLowerCase();
      const villeObj = await this.prisma.ville.findFirst({
        where: { OR: [{ slug: villeSlug }, { nom: { equals: villeSlug, mode: 'insensitive' } }] },
      });
      targetVilleId = villeObj?.id;
    }

    if (!targetVilleId) {
      const premiereVille = await this.prisma.ville.findFirst();
      targetVilleId = premiereVille?.id;
    }

    let targetQuartierId = dto.quartierId;
    if (targetVilleId && dto.quartierNom && dto.quartierNom.trim().length > 0) {
      const qNom = dto.quartierNom.trim();
      let quartierObj = await this.prisma.quartier.findFirst({
        where: {
          villeId: targetVilleId,
          OR: [
            { nom: { equals: qNom, mode: 'insensitive' } },
            { slug: qNom.toLowerCase().replaceAll(' ', '-') },
          ],
        },
      });

      if (!quartierObj) {
        quartierObj = await this.prisma.quartier.create({
          data: {
            villeId: targetVilleId,
            nom: qNom,
            slug: qNom.toLowerCase().replaceAll(' ', '-'),
          },
        });
      }
      targetQuartierId = quartierObj.id;
    }

    if (!targetQuartierId && targetVilleId) {
      const premierQuartier = await this.prisma.quartier.findFirst({ where: { villeId: targetVilleId } });
      targetQuartierId = premierQuartier?.id;
    }

    if (!targetVilleId || !targetQuartierId) {
      throw new BadRequestException('Impossible d\'assigner une ville et un quartier valides au bien.');
    }

    // Calcul de la position floue (~200m) pour masquer la géolocalisation exacte avant la visite
    const latitudeFloue = dto.latitude ? dto.latitude + (Math.random() - 0.5) * 0.003 : undefined;
    const longitudeFloue = dto.longitude ? dto.longitude + (Math.random() - 0.5) * 0.003 : undefined;

    const bien = await this.prisma.bien.create({
      data: {
        reference,
        bailleurId: utilisateurId,
        creeParId: utilisateurId,
        villeId: targetVilleId,
        quartierId: targetQuartierId,
        pointRepereId: dto.pointRepereId,
        indicationAcces: dto.indicationAcces,
        type: dto.type,
        meuble: dto.meuble || false,
        equipements: dto.equipements || [],
        latitude: dto.latitude,
        longitude: dto.longitude,
        latitudeFloue,
        longitudeFloue,
        statut: StatutBien.DISPONIBLE, // Disponible immédiatement à la publication
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

  /// ❤️ Ajouter une annonce aux favoris de l'utilisateur connecté
  async ajouterFavori(utilisateurId: string, annonceId: string) {
    const annonce = await this.prisma.annonce.findUnique({ where: { id: annonceId } });
    if (!annonce) {
      throw new NotFoundException(`Annonce introuvable pour l'ID : ${annonceId}`);
    }

    await this.prisma.favori.upsert({
      where: { utilisateurId_annonceId: { utilisateurId, annonceId } },
      create: { utilisateurId, annonceId },
      update: {},
    });

    return { message: 'Annonce ajoutée aux favoris.' };
  }

  /// 💔 Retirer une annonce des favoris de l'utilisateur connecté
  async retirerFavori(utilisateurId: string, annonceId: string) {
    await this.prisma.favori.deleteMany({
      where: { utilisateurId, annonceId },
    });

    return { message: 'Annonce retirée des favoris.' };
  }

  /// 📋 Récupérer les annonces favorites de l'utilisateur connecté
  async getMesFavoris(utilisateurId: string) {
    const favoris = await this.prisma.favori.findMany({
      where: { utilisateurId },
      orderBy: { createdAt: 'desc' },
      include: {
        annonce: {
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
        },
      },
    });

    return favoris.map((f) => this.formatAnnonceResponse(f.annonce));
  }

  /// 🏘️ Biens du bailleur connecté (tous statuts confondus)
  async getMesBiens(bailleurId: string) {
    const biens = await this.prisma.bien.findMany({
      where: { bailleurId },
      orderBy: { createdAt: 'desc' },
      include: {
        ville: true,
        quartier: true,
        medias: true,
        annonces: { orderBy: { createdAt: 'desc' }, take: 1 },
      },
    });

    return biens.map((bien) => this.formatBienResponse(bien));
  }

  /// ✏️ Modifier un bien (et son annonce active) — réservé au bailleur propriétaire
  async modifierBien(utilisateurId: string, bienId: string, dto: ModifierBienDto) {
    const bien = await this.getBienDuBailleurOuEchoue(utilisateurId, bienId);

    let updatedVilleId: string | undefined;
    if (dto.villeId) {
      const vObj = await this.prisma.ville.findFirst({
        where: { OR: [{ id: dto.villeId }, { slug: dto.villeId.toLowerCase() }, { nom: { equals: dto.villeId, mode: 'insensitive' } }] },
      });
      if (vObj) updatedVilleId = vObj.id;
    }

    let updatedQuartierId: string | undefined;
    if (dto.quartierNom && dto.quartierNom.trim().length > 0) {
      const qNom = dto.quartierNom.trim();
      const targetVille = updatedVilleId || bien.villeId;
      if (targetVille) {
        let qObj = await this.prisma.quartier.findFirst({
          where: {
            villeId: targetVille,
            OR: [
              { nom: { equals: qNom, mode: 'insensitive' } },
              { slug: qNom.toLowerCase().replaceAll(' ', '-') },
            ],
          },
        });
        if (!qObj) {
          qObj = await this.prisma.quartier.create({
            data: {
              villeId: targetVille,
              nom: qNom,
              slug: qNom.toLowerCase().replaceAll(' ', '-'),
            },
          });
        }
        updatedQuartierId = qObj.id;
      }
    }

    // Mettre à jour les attributs du bien
    await this.prisma.bien.update({
      where: { id: bienId },
      data: {
        ...(updatedVilleId ? { villeId: updatedVilleId } : {}),
        ...(updatedQuartierId ? { quartierId: updatedQuartierId } : {}),
        ...(dto.type ? { type: dto.type as any } : {}),
        ...(dto.indicationAcces !== undefined ? { indicationAcces: dto.indicationAcces } : {}),
        ...(dto.meuble !== undefined ? { meuble: dto.meuble } : {}),
        ...(dto.equipements !== undefined ? { equipements: dto.equipements } : {}),
        ...(dto.statut ? { statut: dto.statut as any } : {}),
      },
    });

    const annonce = bien.annonces[0];
    if (annonce) {
      await this.prisma.annonce.update({
        where: { id: annonce.id },
        data: {
          ...(dto.titre ? { titre: dto.titre } : {}),
          ...(dto.description !== undefined ? { description: dto.description } : {}),
          ...(dto.loyerMensuel != null ? { loyerMensuel: BigInt(dto.loyerMensuel) } : {}),
          ...(dto.chargesMensuelles != null ? { chargesMensuelles: BigInt(dto.chargesMensuelles) } : {}),
          ...(dto.avanceMois != null ? { avanceMois: dto.avanceMois } : {}),
          ...(dto.cautionMois != null ? { cautionMois: dto.cautionMois } : {}),
        },
      });
    }

    if (dto.photos && dto.photos.length > 0) {
      // Mettre à jour les médias du bien
      await this.prisma.media.deleteMany({ where: { bienId } });
      await this.prisma.media.createMany({
        data: dto.photos.map((url, index) => ({
          bienId,
          storageKey: url,
          type: 'PHOTO' as any,
          ordre: index,
        })),
      });
    }

    return { message: 'Bien mis à jour avec succès.' };
  }

  /// ✅ Marquer un bien comme loué (fin de disponibilité) — réservé au bailleur propriétaire
  async marquerBienLoue(utilisateurId: string, bienId: string) {
    await this.getBienDuBailleurOuEchoue(utilisateurId, bienId);
    await this.prisma.bien.update({
      where: { id: bienId },
      data: { statut: StatutBien.LOUE },
    });
    return { message: 'Bien marqué comme loué.' };
  }

  /// 🛡️ Valider un bien en attente de vérification — réservé au Staff/Admin
  async validerBien(staffId: string, bienId: string) {
    const bien = await this.prisma.bien.findUnique({ where: { id: bienId } });
    if (!bien) {
      throw new NotFoundException(`Bien introuvable pour l'ID : ${bienId}`);
    }
    await this.prisma.bien.update({
      where: { id: bienId },
      data: {
        statut: StatutBien.DISPONIBLE,
        verifieParId: staffId,
        verifieLe: new Date(),
        motifRejet: null,
      },
    });
    return { message: 'Bien validé et publié dans le catalogue.' };
  }

  /// 🚫 Rejeter un bien en attente de vérification — réservé au Staff/Admin
  async rejeterBien(staffId: string, bienId: string, motif: string) {
    const bien = await this.prisma.bien.findUnique({ where: { id: bienId } });
    if (!bien) {
      throw new NotFoundException(`Bien introuvable pour l'ID : ${bienId}`);
    }
    await this.prisma.bien.update({
      where: { id: bienId },
      data: {
        statut: StatutBien.REJETE,
        verifieParId: staffId,
        verifieLe: new Date(),
        motifRejet: motif,
      },
    });
    return { message: 'Bien rejeté.' };
  }

  private async getBienDuBailleurOuEchoue(utilisateurId: string, bienId: string) {
    const bien = await this.prisma.bien.findUnique({
      where: { id: bienId },
      include: { annonces: { orderBy: { createdAt: 'desc' }, take: 1 } },
    });
    if (!bien) {
      throw new NotFoundException(`Bien introuvable pour l'ID : ${bienId}`);
    }
    if (bien.bailleurId !== utilisateurId) {
      throw new ForbiddenException('Ce bien ne vous appartient pas.');
    }
    return bien;
  }

  private formatBienResponse(bien: any) {
    const annonce = bien.annonces?.[0];
    return {
      id: bien.id,
      reference: bien.reference,
      type: bien.type,
      statut: bien.statut,
      motifRejet: bien.motifRejet,
      meuble: bien.meuble,
      equipements: bien.equipements,
      ville: bien.ville?.nom,
      quartier: bien.quartier?.nom,
      photos: bien.medias?.map((m: any) => m.storageKey) ?? [],
      annonceId: annonce?.id,
      titre: annonce?.titre,
      loyerMensuelXAF: annonce ? Number(annonce.loyerMensuel) : null,
      createdAt: bien.createdAt,
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
        statut: item.bien.statut,
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
    if (!bonaQuartier) {
      this.logger.warn('Quartier "bonamoussadi" introuvable : seed des annonces ignoré (le seed géographique doit s\'exécuter avant).');
      return;
    }

    // Sur une base fraîche, aucun utilisateur n'existe encore : on crée un compte
    // système dédié plutôt que de dépendre silencieusement d'un premier utilisateur.
    let userAdmin = await this.prisma.utilisateur.findFirst();
    if (!userAdmin) {
      userAdmin = await this.prisma.utilisateur.create({
        data: {
          telephone: '+237600000000',
          telephoneVerifie: true,
          nomComplet: 'Système LocaDirect',
          roles: ['STAFF'],
        },
      });
    }

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
