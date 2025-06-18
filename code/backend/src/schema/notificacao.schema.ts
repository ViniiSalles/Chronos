// src/notifications/schemas/notification.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type NotificationDocument = Notification & Document;

// Enum para os tipos de evento que geram notificações
export enum NotificationEventType {
  TASK_UPDATED = 'TASK_UPDATED',
  TASK_COMPLETED = 'TASK_COMPLETED',
  TASK_ACKNOWLEDGEMENT = 'TASK_ACKNOWLEDGEMENT', // Confirmação de recebimento
  TASK_REVIEWED = 'TASK_REVIEWED',
  PROJECT_UPDATED = 'PROJECT_UPDATED',
  PROJECT_MEMBER_ADDED = 'PROJECT_MEMBER_ADDED',
  MEETING_CREATED = 'MEETING_CREATED',
  MEETING_UPDATED = 'MEETING_UPDATED',
  MEETING_NEAR_START = 'MEETING_NEAR_START', // Próxima reunião
  // ... adicione outros tipos conforme necessário
}

@Schema({ timestamps: true }) // Adiciona createdAt e updatedAt automaticamente
export class Notification {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  recipient: Types.ObjectId; // O usuário que deve receber esta notificação

  @Prop({ required: true })
  message: string; // A mensagem principal da notificação (ex: "Sua tarefa 'XYZ' foi atualizada")

  @Prop({ enum: NotificationEventType, required: true })
  eventType: NotificationEventType; // O tipo de evento que disparou a notificação

  @Prop({ type: Types.ObjectId, refPath: 'relatedToModel' }) // Referência polimórfica
  relatedToId?: Types.ObjectId; // ID do item relacionado (tarefa, projeto, reunião, etc.)

  @Prop({
    type: String,
    enum: ['Task', 'Project', 'Meeting', 'User'],
    required: false,
  })
  relatedToModel?: string; // O nome do modelo ao qual relatedToId se refere

  @Prop({ default: false })
  read: boolean; // Se a notificação foi lida pelo usuário

  @Prop()
  readAt?: Date; // Data/hora em que a notificação foi lida

  // Opcional: Dados adicionais para o frontend (ex: status antigo, novo status)
  @Prop({ type: Object })
  metadata?: Record<string, any>;
}

export const NotificationSchema = SchemaFactory.createForClass(Notification);

// Virtual para 'id'
NotificationSchema.virtual('id').get(function () {
  return (this as any)._id.toHexString();
});

NotificationSchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    delete ret.__v;
  },
});
NotificationSchema.set('toObject', { virtuals: true });
