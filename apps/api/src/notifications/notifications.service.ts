import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

/// 🔔 Notifications in-app uniquement (aucun provider SMS/push configuré ce soir).
/// `canal` reste un champ libre sur le modèle pour permettre l'ajout ultérieur
/// de SMS/WhatsApp sans migration, mais seul `IN_APP` est émis pour l'instant.
@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(private prisma: PrismaService) {}

  async creer(utilisateurId: string, gabarit: string, variables: Record<string, unknown> = {}) {
    try {
      return await this.prisma.notification.create({
        data: {
          utilisateurId,
          canal: 'IN_APP',
          gabarit,
          variables: variables as any,
          envoyeLe: new Date(),
        },
      });
    } catch (err) {
      // Best-effort : une notification ratée ne doit jamais faire échouer l'action métier.
      this.logger.error(`Échec de création de notification (${gabarit} → ${utilisateurId}) : ${(err as Error).message}`);
      return null;
    }
  }

  /// 📋 Notifications de l'utilisateur connecté, plus récentes en premier
  async getMesNotifications(utilisateurId: string) {
    const notifications = await this.prisma.notification.findMany({
      where: { utilisateurId },
      orderBy: { envoyeLe: 'desc' },
    });
    return notifications.map((n) => this.format(n));
  }

  /// ✅ Marquer une notification comme lue — réservé à son destinataire
  async marquerLue(utilisateurId: string, id: string) {
    const notification = await this.prisma.notification.findUnique({ where: { id } });
    if (!notification) {
      throw new NotFoundException(`Notification introuvable pour l'ID : ${id}`);
    }
    if (notification.utilisateurId !== utilisateurId) {
      throw new ForbiddenException('Cette notification ne vous appartient pas.');
    }
    const updated = await this.prisma.notification.update({
      where: { id },
      data: { luLe: new Date() },
    });
    return this.format(updated);
  }

  private format(n: any) {
    return {
      id: n.id,
      canal: n.canal,
      gabarit: n.gabarit,
      variables: n.variables,
      envoyeLe: n.envoyeLe,
      luLe: n.luLe,
    };
  }
}
