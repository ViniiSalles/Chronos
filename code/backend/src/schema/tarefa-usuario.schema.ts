import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type TaskUserDocument = TaskUser & Document;

@Schema({ timestamps: true })
export class TaskUser {
  @Prop({ type: Types.ObjectId, ref: 'Task', required: true })
  task_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  user_id: Types.ObjectId;

  @Prop({ default: false })
  notificado_relacionada: boolean;

  @Prop()
  concluida_em?: Date;

  @Prop()
  tempo_gasto_horas?: number;

  @Prop()
  avaliacao_comentario?: string;

  @Prop()
  avaliacao_nota?: number;

  @Prop()
  avaliacao_codigo?: string;
}

export const TaskUserSchema = SchemaFactory.createForClass(TaskUser);
