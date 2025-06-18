// src/notifications/notification.service.ts
import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { CreateNotificationDto } from './dto/create-notification.dto';
import {
  NotificationDocument,
  Notification,
} from 'src/schema/notificacao.schema';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    @InjectModel(Notification.name) // Agora 'Notification.name' está definido porque a classe Notification foi importada
    private notificationModel: Model<NotificationDocument>,
  ) {}

  /**
   * Cria e salva uma nova notificação no banco de dados.
   * @param dto Os dados para criar a notificação.
   * @returns A notificação criada.
   */
  async createNotification(
    dto: CreateNotificationDto,
  ): Promise<NotificationDocument> {
    try {
      const newNotification = new this.notificationModel({
        recipient: new Types.ObjectId(dto.recipient),
        message: dto.message,
        eventType: dto.eventType,
        relatedToId: dto.relatedToId
          ? new Types.ObjectId(dto.relatedToId)
          : undefined,
        relatedToModel: dto.relatedToModel,
        read: dto.read ?? false, // Padrão para não lida
      });

      const savedNotification = await newNotification.save();
      this.logger.log(
        `Notificação criada para ${dto.recipient}: ${dto.message}`,
      );
      return savedNotification;
    } catch (error) {
      this.logger.error(
        `Erro ao criar notificação: ${error.message}`,
        error.stack,
      );
      throw new BadRequestException(
        `Falha ao criar notificação: ${error.message}`,
      );
    }
  }

  /**
   * Busca todas as notificações para um destinatário específico, com filtro opcional por status de leitura.
   * @param recipientId O ID do usuário destinatário.
   * @param filter Objeto de filtro (ex: { read: true }).
   * @returns Uma lista de notificações.
   */
  async findByRecipient(
    recipientId: string,
    filter?: { read?: boolean },
  ): Promise<NotificationDocument[]> {
    const query: any = { recipient: new Types.ObjectId(recipientId) };

    if (filter?.read !== undefined) {
      query.read = filter.read;
    }

    try {
      const notifications = await this.notificationModel
        .find(query)
        .sort({ createdAt: -1 }) // Ordenar por mais recente primeiro
        .lean() // Retorna objetos JavaScript puros, mais rápidos para leitura
        .exec();
      return notifications;
    } catch (error) {
      this.logger.error(
        `Erro ao buscar notificações para ${recipientId}: ${error.message}`,
        error.stack,
      );
      throw new BadRequestException(
        `Falha ao buscar notificações: ${error.message}`,
      );
    }
  }

  /**
   * Marca uma notificação específica como lida.
   * @param notificationId O ID da notificação.
   * @param userId O ID do usuário que está marcando (deve ser o destinatário).
   * @returns A notificação atualizada.
   */
  async markAsRead(
    notificationId: string,
    userId: string,
  ): Promise<NotificationDocument> {
    const notification = await this.notificationModel
      .findById(notificationId)
      .exec();

    if (!notification) {
      throw new NotFoundException('Notificação não encontrada.');
    }

    if (notification.recipient.toString() !== userId) {
      throw new BadRequestException(
        'Você não tem permissão para marcar esta notificação como lida.',
      );
    }

    if (notification.read) {
      this.logger.warn(
        `Notificação ${notificationId} já estava marcada como lida.`,
      );
      return notification; // Já lida, retorna o documento Mongoose
    }

    notification.read = true;
    notification.readAt = new Date();
    const updatedNotification = await notification.save();
    this.logger.log(
      `Notificação ${notificationId} marcada como lida por ${userId}.`,
    );
    return updatedNotification;
  }

  /**
   * Marca todas as notificações não lidas de um usuário como lidas.
   * @param userId O ID do usuário.
   * @returns Um objeto com a contagem de modificações.
   */
  async markAllAsRead(
    userId: string,
  ): Promise<{ acknowledged: boolean; modifiedCount: number }> {
    try {
      const result = await this.notificationModel
        .updateMany(
          { recipient: new Types.ObjectId(userId), read: false },
          { $set: { read: true, readAt: new Date() } },
        )
        .exec();
      this.logger.log(
        `Todas as notificações não lidas para ${userId} marcadas como lidas. Modificadas: ${result.modifiedCount}`,
      );
      return {
        acknowledged: result.acknowledged,
        modifiedCount: result.modifiedCount,
      };
    } catch (error) {
      this.logger.error(
        `Erro ao marcar todas as notificações de ${userId} como lidas: ${error.message}`,
        error.stack,
      );
      throw new BadRequestException(
        `Falha ao marcar todas as notificações como lidas: ${error.message}`,
      );
    }
  }

  // Você pode adicionar um método para remover notificações (por ID, ou todas lidas, etc.) se necessário
  /*
  async removeNotification(notificationId: string, userId: string): Promise<void> {
    const result = await this.notificationModel.deleteOne({ _id: notificationId, recipient: userId }).exec();
    if (result.deletedCount === 0) {
      throw new NotFoundException('Notificação não encontrada ou você não tem permissão para removê-la.');
    }
    this.logger.log(`Notificação ${notificationId} removida por ${userId}.`);
  }
  */
}
