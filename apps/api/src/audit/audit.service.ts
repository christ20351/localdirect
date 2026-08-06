import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

/// 🗒️ Journalisation des actions sensibles (modération, décisions de bail, etc.)
/// Best-effort : une erreur d'écriture d'audit ne doit jamais faire échouer
/// l'action métier qu'elle documente, elle est donc avalée et seulement logguée.
@Injectable()
export class AuditService {
  private readonly logger = new Logger(AuditService.name);

  constructor(private prisma: PrismaService) {}

  async log(
    acteurId: string | null | undefined,
    action: string,
    entite: string,
    entiteId?: string | null,
    avant?: unknown,
    apres?: unknown,
    ip?: string | null,
  ) {
    try {
      await this.prisma.journalAudit.create({
        data: {
          acteurId: acteurId || undefined,
          action,
          entite,
          entiteId: entiteId || undefined,
          avant: avant === undefined ? undefined : (avant as any),
          apres: apres === undefined ? undefined : (apres as any),
          ip: ip || undefined,
        },
      });
    } catch (err) {
      this.logger.error(`Échec d'écriture du journal d'audit (${action} / ${entite}) : ${(err as Error).message}`);
    }
  }

  /// 📋 Dernières entrées du journal, paginées, plus récentes en premier
  async getEntries(page: number, limit: number, entite?: string) {
    const skip = (page - 1) * limit;
    const where = entite ? { entite } : {};
    const [total, entries] = await Promise.all([
      this.prisma.journalAudit.count({ where }),
      this.prisma.journalAudit.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: {
          acteur: { select: { id: true, nomComplet: true, telephone: true, roles: true } },
        },
      }),
    ]);

    return {
      data: entries.map((e) => ({
        id: e.id.toString(),
        acteur: e.acteur ? { id: e.acteur.id, nomComplet: e.acteur.nomComplet, telephone: e.acteur.telephone, roles: e.acteur.roles } : null,
        action: e.action,
        entite: e.entite,
        entiteId: e.entiteId,
        avant: e.avant,
        apres: e.apres,
        ip: e.ip,
        createdAt: e.createdAt,
      })),
      meta: {
        total,
        page,
        limit,
        pagesTotal: Math.ceil(total / limit),
      },
    };
  }
}
