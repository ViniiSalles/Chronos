import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

// Renomeando para corresponder ao seu schema, mas mantendo a exportação clara
export type AvaliacaoTaskDocument = AvaliacaoTask & Document;

@Schema({ timestamps: true })
export class AvaliacaoTask {
  @Prop({ type: Types.ObjectId, ref: 'Tarefa', required: true })
  task_id: Types.ObjectId;

  // ID do usuário que executou a tarefa
  @Prop({ type: Types.ObjectId, ref: 'Usuario'})
  user_id_do_avaliado: Types.ObjectId;

  // CAMPO ADICIONADO: ID do usuário que fez a avaliação (o gerente/admin)
  @Prop({ type: Types.ObjectId, ref: 'Usuario'})
  user_id_do_avaliador: Types.ObjectId;

  @Prop()
  nota: number;

  @Prop({ required: false })
  code: string;

  @Prop({ default: Date.now })
  data_avaliacao: Date;

  @Prop({ default: false })
  gerada_automaticamente: boolean;
}

export const AvaliacaoTaskSchema = SchemaFactory.createForClass(AvaliacaoTask);
