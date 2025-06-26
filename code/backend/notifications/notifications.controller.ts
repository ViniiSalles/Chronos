// src/notifications/notification.controller.ts
import {
  Controller,
  Get,
  Patch,
  Param,
  Query,
  Req,
  UseGuards,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { FirebaseAuthGuard } from 'auth/firebase-auth.guard'; // Seu guard de autenticação Firebase
import { NotificationService } from './notifications.service';

@Controller('notifications')
@UseGuards(FirebaseAuthGuard) // Protege todas as rotas deste controller
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  /**
   * GET /notifications
   * Busca todas as notificações do usuário logado, com filtro opcional.
   * @param req O objeto de requisição (contém user do FirebaseAuthGuard).
   * @param read Opcional: filtrar por notificações lidas (true/false).
   * @returns Uma lista de notificações.
   */
  @Get()
  async findMyNotifications(@Req() req: any, @Query('read') read?: string) {
    const userId = req.user?._id;
    if (!userId) {
      throw new NotFoundException('ID do usuário autenticado não encontrado.');
    }

    let readFilter: boolean | undefined;
    if (read !== undefined) {
      if (read === 'true') {
        readFilter = true;
      } else if (read === 'false') {
        readFilter = false;
      } else {
        throw new BadRequestException(
          'O parâmetro "read" deve ser "true" ou "false".',
        );
      }
    }

    return this.notificationService.findByRecipient(userId.toString(), {
      read: readFilter,
    });
  }

  /**
   * PATCH /notifications/:id/read
   * Marca uma notificação específica como lida.
   * @param id O ID da notificação.
   * @param req O objeto de requisição.
   * @returns A notificação atualizada.
   */
  @Patch(':id/read')
  async markNotificationAsRead(
    @Param('id') notificationId: string,
    @Req() req: any,
  ) {
    const userId = req.user?._id;
    if (!userId) {
      throw new NotFoundException('ID do usuário autenticado não encontrado.');
    }
    return this.notificationService.markAsRead(
      notificationId,
      userId.toString(),
    );
  }

  /**
   * PATCH /notifications/mark-all-as-read
   * Marca todas as notificações não lidas do usuário logado como lidas.
   * @param req O objeto de requisição.
   * @returns Um objeto com a contagem de modificações.
   */
  @Patch('mark-all-as-read')
  async markAllNotificationsAsRead(@Req() req: any) {
    const userId = req.user?._id;
    if (!userId) {
      throw new NotFoundException('ID do usuário autenticado não encontrado.');
    }
    return this.notificationService.markAllAsRead(userId.toString());
  }

  // Exemplo de como um endpoint de DELETAR notificação poderia ser
  /*
  @Delete(':id')
  async deleteNotification(@Param('id') notificationId: string, @Req() req: any) {
    const userId = req.user?._id;
    if (!userId) {
      throw new NotFoundException('ID do usuário autenticado não encontrado.');
    }
    // Implemente a lógica no service para verificar se o usuário é o destinatário antes de deletar
    await this.notificationService.removeNotification(notificationId, userId.toString());
    return { message: 'Notificação removida com sucesso.' };
  }
  */
}
