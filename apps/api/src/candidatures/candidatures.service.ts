import { Injectable, NotFoundException, ConflictException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreerCandidatureDto } from './dtos/creer-candidature.dto';
import { DeciderCandidatureDto } from './dtos/decider-candidature.dto';
import { StatutBien } from '@prisma/client';

@Injectable()
export class CandidaturesService {
  constructor(private prisma: PrismaService) {}

  /// 📋 Soumettre un dossier de candidature sur une annonce (locataire)
  /// Simplification volontaire par rapport au cahier des charges : soumission directe
  /// en un seul appel (pas d'étape BROUILLON séparée), adaptée à un formulaire mobile unique.
  async soumettreCandidature(locataireId: string, annonceId: string, dto: CreerCandidatureDto) {
    const annonce = await this.prisma.annonce.findUnique({ where: { id: annonceId } });
    if (!annonce) {
      throw new NotFoundException(`Annonce introuvable pour l'ID : ${annonceId}`);
    }

    const existante = await this.prisma.candidature.findUnique({
      where: { annonceId_locataireId: { annonceId, locataireId } },
    });
    if (existante) {
      throw new ConflictException('Vous avez déjà soumis un dossier pour cette annonce.');
    }

    let garantId: string | undefined;
    if (dto.garantNomComplet && dto.garantTelephone) {
      const garant = await this.prisma.garant.create({
        data: {
          locataireId,
          nomComplet: dto.garantNomComplet,
          telephone: dto.garantTelephone,
          profession: dto.garantProfession,
          lien: dto.garantLien,
        },
      });
      garantId = garant.id;
    }

    const candidature = await this.prisma.candidature.create({
      data: {
        annonceId,
        locataireId,
        statut: 'SOUMISE',
        revenuDeclare: dto.revenuDeclare != null ? BigInt(dto.revenuDeclare) : undefined,
        sourceRevenu: dto.sourceRevenu,
        nbOccupants: dto.nbOccupants,
        message: dto.message,
        garantId,
        soumiseLe: new Date(),
      },
      include: { garant: true, annonce: { include: { bien: { include: { ville: true, quartier: true } } } } },
    });

    return this.formatCandidature(candidature);
  }

  /// 🔍 Détail d'une candidature (propriétaire uniquement)
  async getCandidature(userId: string, id: string) {
    const candidature = await this.getCandidatureOuEchoue(id);
    if (candidature.locataireId !== userId) {
      throw new ForbiddenException('Ce dossier ne vous appartient pas.');
    }
    return this.formatCandidature(candidature);
  }

  /// 📋 Dossiers du locataire connecté
  async getMesCandidatures(locataireId: string) {
    const candidatures = await this.prisma.candidature.findMany({
      where: { locataireId },
      orderBy: { soumiseLe: 'desc' },
      include: { garant: true, annonce: { include: { bien: { include: { ville: true, quartier: true } } } } },
    });
    return candidatures.map((c) => this.formatCandidature(c));
  }

  /// 📋 Dossiers reçus sur les biens du bailleur connecté
  async getCandidaturesBailleur(bailleurId: string) {
    const candidatures = await this.prisma.candidature.findMany({
      where: { annonce: { bien: { bailleurId } } },
      orderBy: { soumiseLe: 'desc' },
      include: {
        garant: true,
        locataire: { select: { nomComplet: true, telephone: true, statutKyc: true } },
        annonce: { include: { bien: { include: { ville: true, quartier: true } } } },
      },
    });
    return candidatures.map((c) => this.formatCandidature(c, true));
  }

  /// ⚖️ Décision du bailleur sur un dossier de candidature (acceptation → génère le bail, refus → motif)
  async deciderCandidature(bailleurId: string, id: string, dto: DeciderCandidatureDto) {
    const candidature = await this.prisma.candidature.findUnique({
      where: { id },
      include: { annonce: { include: { bien: true } } },
    });
    if (!candidature) {
      throw new NotFoundException(`Dossier introuvable pour l'ID : ${id}`);
    }
    if (candidature.annonce.bien.bailleurId !== bailleurId) {
      throw new ForbiddenException("Ce dossier ne concerne pas un bien dont vous êtes le bailleur.");
    }
    if (candidature.statut === 'ACCEPTEE' || candidature.statut === 'REFUSEE') {
      throw new ConflictException('Ce dossier a déjà été traité.');
    }

    if (dto.decision === 'REFUSEE') {
      await this.prisma.candidature.update({
        where: { id },
        data: { statut: 'REFUSEE', motifRefus: dto.motif, decideeLe: new Date() },
      });
      return { message: 'Dossier refusé.' };
    }

    const annonce = candidature.annonce;
    const bien = candidature.annonce.bien;
    if (!bien.bailleurId) {
      throw new BadRequestException('Ce bien n\'a pas de bailleur assigné.');
    }

    const bail = await this.prisma.$transaction(async (tx) => {
      const nouveauBail = await tx.bail.create({
        data: {
          reference: `BAIL-${Date.now().toString().substring(6)}`,
          bienId: bien.id,
          bailleurId: bien.bailleurId!,
          locataireId: candidature.locataireId,
          candidatureId: candidature.id,
          statut: 'PROJET',
          dateDebut: new Date(),
          loyerMensuel: annonce.loyerMensuel,
          chargesMensuelles: annonce.chargesMensuelles,
          avanceMois: annonce.avanceMois,
          avanceMontant: annonce.loyerMensuel * BigInt(annonce.avanceMois),
          cautionMontant: annonce.loyerMensuel * BigInt(annonce.cautionMois),
        },
      });

      await tx.candidature.update({
        where: { id },
        data: { statut: 'ACCEPTEE', decideeLe: new Date() },
      });

      await tx.bien.update({
        where: { id: bien.id },
        data: { statut: StatutBien.RESERVE },
      });

      return nouveauBail;
    });

    return { message: 'Dossier accepté, un bail a été créé.', bailId: bail.id };
  }

  private async getCandidatureOuEchoue(id: string) {
    const candidature = await this.prisma.candidature.findUnique({
      where: { id },
      include: { garant: true, annonce: { include: { bien: { include: { ville: true, quartier: true } } } } },
    });
    if (!candidature) {
      throw new NotFoundException(`Dossier introuvable pour l'ID : ${id}`);
    }
    return candidature;
  }

  private formatCandidature(candidature: any, avecLocataire = false) {
    return {
      id: candidature.id,
      annonceId: candidature.annonceId,
      statut: candidature.statut,
      revenuDeclareXAF: candidature.revenuDeclare != null ? Number(candidature.revenuDeclare) : null,
      sourceRevenu: candidature.sourceRevenu,
      nbOccupants: candidature.nbOccupants,
      message: candidature.message,
      motifRefus: candidature.motifRefus,
      soumiseLe: candidature.soumiseLe,
      decideeLe: candidature.decideeLe,
      locataire: avecLocataire && candidature.locataire
        ? {
            nomComplet: candidature.locataire.nomComplet,
            telephone: candidature.locataire.telephone,
            statutKyc: candidature.locataire.statutKyc,
          }
        : undefined,
      garant: candidature.garant
        ? {
            nomComplet: candidature.garant.nomComplet,
            telephone: candidature.garant.telephone,
            profession: candidature.garant.profession,
            lien: candidature.garant.lien,
            verifie: candidature.garant.verifie,
          }
        : null,
      annonce: candidature.annonce
        ? {
            id: candidature.annonce.id,
            titre: candidature.annonce.titre,
            ville: candidature.annonce.bien?.ville?.nom,
            quartier: candidature.annonce.bien?.quartier?.nom,
            loyerMensuelXAF: Number(candidature.annonce.loyerMensuel),
          }
        : undefined,
    };
  }
}
