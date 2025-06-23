import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type AvaliacaoTaskDocument = AvaliacaoTask & Document;

@Schema()
export class AvaliacaoTask {
  @Prop({ required: false, type: Types.ObjectId, ref: 'Task' }) // CORRIGIDO: Mudar para Types.ObjectId e adicionar ref
  task_id: Types.ObjectId; // Agora, este campo aceita ObjectId

  @Prop({ type: Types.ObjectId, ref: 'User', required: true }) // Campo user_id_do_avaliado
  user_id_do_avaliado: Types.ObjectId;

  @Prop({ required: false }) nota: number;
  @Prop({ required: false }) data_avaliacao: Date;
  @Prop({ required: false }) gerada_automaticamente: boolean;
  @Prop({ required: true }) code: string;
}
export const AvaliacaoTaskSchema = SchemaFactory.createForClass(AvaliacaoTask);
