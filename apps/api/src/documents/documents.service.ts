import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { createHash } from 'crypto';
import * as fs from 'fs';
import { PrismaService } from '../prisma/prisma.service';
import { StatutKyc } from '@prisma/client';
import { SoumettreDocumentDto } from './dtos/soumettre-document.dto';
import { AuditService } from '../audit/audit.service';

@Injectable()
export class DocumentsService {
  constructor(
    private prisma: PrismaService,
    private auditService: AuditService,
  ) {}

  /// 📎 Soumettre un document (KYC compte ou preuve de propriété d'un bien)
  async soumettre(utilisateurId: string, file: Express.Multer.File, dto: SoumettreDocumentDto) {
    if (!file) {
      throw new BadRequestException('Aucun fichier reçu.');
    }

    if (dto.bienId) {
      const bien = await this.prisma.bien.findUnique({ where: { id: dto.bienId } });
      if (!bien) {
        throw new NotFoundException(`Bien introuvable pour l'ID : ${dto.bienId}`);
      }
      if (bien.bailleurId !== utilisateurId && bien.creeParId !== utilisateurId) {
        throw new ForbiddenException('Ce bien ne vous appartient pas.');
      }
    }

    const hashSha256 = createHash('sha256').update(fs.readFileSync(file.path)).digest('hex');

    const document = await this.prisma.documentVerification.create({
      data: {
        utilisateurId,
        bienId: dto.bienId,
        type: dto.type,
        storageKey: file.path,
        hashSha256,
        statut: StatutKyc.EN_ATTENTE,
      },
    });

    // Compte : premier document soumis → le profil passe "en attente" de vérification.
    if (!dto.bienId) {
      await this.prisma.utilisateur.updateMany({
        where: { id: utilisateurId, statutKyc: StatutKyc.NON_SOUMIS },
        data: { statutKyc: StatutKyc.EN_ATTENTE },
      });
    }

    return this.formatDocument(document);
  }

  /// 📋 Documents soumis par l'utilisateur connecté (compte ou un bien précis)
  async getMesDocuments(utilisateurId: string, bienId?: string) {
    const documents = await this.prisma.documentVerification.findMany({
      where: { utilisateurId, ...(bienId ? { bienId } : {}) },
      orderBy: { createdAt: 'desc' },
    });
    return documents.map((d) => this.formatDocument(d));
  }

  /// 🛡️ File d'attente de modération — Staff/Admin
  async getFileAttente(statut?: string) {
    const documents = await this.prisma.documentVerification.findMany({
      where: statut ? { statut: statut as StatutKyc } : {},
      orderBy: { createdAt: 'asc' },
      include: {
        utilisateur: { select: { id: true, nomComplet: true, telephone: true } },
        bien: { select: { id: true, reference: true } },
      },
    });
    return documents.map((d) => ({
      ...this.formatDocument(d),
      utilisateur: d.utilisateur,
      bien: d.bien,
    }));
  }

  /// ✅ Valider un document — Staff/Admin
  async valider(staffId: string, documentId: string) {
    const avant = await this.getDocumentOuEchoue(documentId);
    const updated = await this.prisma.documentVerification.update({
      where: { id: documentId },
      data: { statut: StatutKyc.VALIDE, verifieParId: staffId, verifieLe: new Date(), motifRejet: null },
    });
    await this.recalculerStatutKycCompte(updated.utilisateurId);
    await this.auditService.log(staffId, 'DOCUMENT_VALIDE', 'DocumentVerification', documentId, { statut: avant.statut }, { statut: StatutKyc.VALIDE });
    return this.formatDocument(updated);
  }

  /// 🚫 Rejeter un document — Staff/Admin
  async rejeter(staffId: string, documentId: string, motif: string) {
    const avant = await this.getDocumentOuEchoue(documentId);
    const updated = await this.prisma.documentVerification.update({
      where: { id: documentId },
      data: { statut: StatutKyc.REJETE, verifieParId: staffId, verifieLe: new Date(), motifRejet: motif },
    });
    await this.recalculerStatutKycCompte(updated.utilisateurId);
    await this.auditService.log(staffId, 'DOCUMENT_REJETE', 'DocumentVerification', documentId, { statut: avant.statut }, { statut: StatutKyc.REJETE, motif });
    return this.formatDocument(updated);
  }

  /// 📥 Chemin disque d'un document, avec contrôle d'accès (propriétaire ou Staff/Admin)
  async getCheminFichier(requesterId: string, requesterRoles: string[], documentId: string) {
    const document = await this.getDocumentOuEchoue(documentId);
    const estStaff = requesterRoles.includes('STAFF') || requesterRoles.includes('ADMIN');
    if (document.utilisateurId !== requesterId && !estStaff) {
      throw new ForbiddenException('Ce document ne vous appartient pas.');
    }
    return document.storageKey;
  }

  /// 🔢 Nombre de documents de preuve de propriété validés pour un bien donné
  async countDocumentsBienValides(bienId: string) {
    return this.prisma.documentVerification.count({
      where: { bienId, statut: StatutKyc.VALIDE },
    });
  }

  /// 🔢 Documents de compte (KYC) validés d'un type donné pour un utilisateur
  async countDocumentsCompteValides(utilisateurId: string, types: readonly string[]) {
    return this.prisma.documentVerification.count({
      where: { utilisateurId, bienId: null, type: { in: [...types] }, statut: StatutKyc.VALIDE },
    });
  }

  /// Si tous les documents de compte d'un utilisateur sont traités et qu'aucun n'est
  /// plus en attente, on peut affiner statutKyc (VALIDE si au moins un validé, REJETE sinon).
  private async recalculerStatutKycCompte(utilisateurId: string) {
    const enAttente = await this.prisma.documentVerification.count({
      where: { utilisateurId, bienId: null, statut: StatutKyc.EN_ATTENTE },
    });
    if (enAttente > 0) return;

    const valides = await this.prisma.documentVerification.count({
      where: { utilisateurId, bienId: null, statut: StatutKyc.VALIDE },
    });

    await this.prisma.utilisateur.update({
      where: { id: utilisateurId },
      data: { statutKyc: valides > 0 ? StatutKyc.VALIDE : StatutKyc.REJETE },
    });
  }

  private async getDocumentOuEchoue(documentId: string) {
    const document = await this.prisma.documentVerification.findUnique({ where: { id: documentId } });
    if (!document) {
      throw new NotFoundException(`Document introuvable pour l'ID : ${documentId}`);
    }
    return document;
  }

  private formatDocument(document: any) {
    return {
      id: document.id,
      bienId: document.bienId,
      type: document.type,
      statut: document.statut,
      motifRejet: document.motifRejet,
      verifieLe: document.verifieLe,
      createdAt: document.createdAt,
    };
  }
}
