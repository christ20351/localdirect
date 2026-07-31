import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreerAlerteDto } from './dtos/creer-alerte.dto';

/**
 * Alertes de recherche : critères sauvegardés + compteur de nouvelles annonces
 * correspondantes calculé à la demande (pull). Pas de notification push/SMS/WhatsApp
 * réelle : l'infra (FCM, agrégateur SMS) n'est pas branchée sur ce projet. L'UI doit
 * rester honnête là-dessus plutôt que de promettre une notification qui n'arrivera jamais.
 */
@Injectable()
export class AlertesService {
  constructor(private prisma: PrismaService) {}

  async creerAlerte(utilisateurId: string, dto: CreerAlerteDto) {
    const criteres = {
      ville: dto.villeSlug ?? null,
      type: dto.type ?? null,
      loyerMax: dto.loyerMax ?? null,
    };

    const alerte = await this.prisma.alerteRecherche.create({
      data: { utilisateurId, criteres, derniereNotif: new Date() },
    });

    return this.formatAlerte(alerte, 0);
  }

  async getMesAlertes(utilisateurId: string) {
    const alertes = await this.prisma.alerteRecherche.findMany({
      where: { utilisateurId, actif: true },
    });

    return Promise.all(
      alertes.map(async (alerte) => {
        const nouvelles = await this.compterNouvellesCorrespondances(alerte);
        return this.formatAlerte(alerte, nouvelles);
      }),
    );
  }

  async supprimerAlerte(utilisateurId: string, id: string) {
    const alerte = await this.getAlerteOuEchoue(id);
    if (alerte.utilisateurId !== utilisateurId) {
      throw new ForbiddenException('Cette alerte ne vous appartient pas.');
    }
    await this.prisma.alerteRecherche.delete({ where: { id } });
    return { message: 'Alerte supprimée.' };
  }

  /// Réinitialise le compteur de nouvelles correspondances (l'utilisateur a consulté l'alerte).
  async marquerVue(utilisateurId: string, id: string) {
    const alerte = await this.getAlerteOuEchoue(id);
    if (alerte.utilisateurId !== utilisateurId) {
      throw new ForbiddenException('Cette alerte ne vous appartient pas.');
    }
    const updated = await this.prisma.alerteRecherche.update({
      where: { id },
      data: { derniereNotif: new Date() },
    });
    return this.formatAlerte(updated, 0);
  }

  private async getAlerteOuEchoue(id: string) {
    const alerte = await this.prisma.alerteRecherche.findUnique({ where: { id } });
    if (!alerte) {
      throw new NotFoundException(`Alerte introuvable pour l'ID : ${id}`);
    }
    return alerte;
  }

  private async compterNouvellesCorrespondances(alerte: { criteres: any; derniereNotif: Date | null }) {
    const criteres = (alerte.criteres as Record<string, any>) ?? {};
    const where: any = {
      bien: { statut: 'DISPONIBLE' },
      createdAt: { gt: alerte.derniereNotif ?? new Date(0) },
    };
    if (criteres.ville) where.bien.ville = { slug: criteres.ville };
    if (criteres.type) where.bien.type = criteres.type;
    if (criteres.loyerMax) where.loyerMensuel = { lte: BigInt(criteres.loyerMax) };

    return this.prisma.annonce.count({ where });
  }

  private formatAlerte(alerte: any, nouvellesCorrespondances: number) {
    return {
      id: alerte.id,
      criteres: alerte.criteres,
      nouvellesCorrespondances,
    };
  }
}
