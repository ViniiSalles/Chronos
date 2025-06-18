import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type NotificacaoUserDocument = NotificacaoUser & Document;

@Schema()
export class NotificacaoUser {
  @Prop({ unique: true, required: true }) id: number;
  @Prop({ required: true }) notificacao_id: number;
  @Prop({ required: true }) user_id: number;
  @Prop({ required: false }) visualizada_em: Date;
}

export const NotificacaoUserSchema =
  SchemaFactory.createForClass(NotificacaoUser);
