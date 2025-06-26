import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { v4 as uuidv4 } from 'uuid';
import { Complexidade } from '../types/types'; // Supondo que o enum Complexidade esteja em types.ts

// O nome do tipo de documento também foi atualizado para TaskDocument
export type TaskDocument = Task & Document;

@Schema({ timestamps: true })
export class Task {
  @Prop({ type: String, default: () => uuidv4(), unique: true })
  id: string;

  @Prop({ required: true })
  titulo: string;

  @Prop()
  descricao?: string;

  @Prop({ required: true, default: 'pending' })
  status: string;

  @Prop()
  dataInicio?: Date;

  @Prop()
  dataLimite?: Date;

  @Prop()
  dataConclusao?: Date;

  @Prop({ required: true })
  prioridade: string;

  @Prop({ enum: Complexidade, required: true })
  complexidade: Complexidade;

  @Prop({ type: Types.ObjectId, ref: 'Project', required: true })
  projeto: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  criadaPor: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  aprovadaPor?: Types.ObjectId;

  // Corresponde a 'responsaveis' do schema anterior, agora como 'atribuicoes'
  @Prop([{ type: Types.ObjectId, ref: 'User' }])
  atribuicoes?: Types.ObjectId[];

  @Prop({ type: [{ type: Types.ObjectId, ref: 'Task' }], default: [] })
  tarefasAnteriores: Types.ObjectId[];

  // Corresponde a 'avaliacao' do schema anterior, agora como 'avaliacaoId'
  @Prop({ type: Types.ObjectId, ref: 'AvaliacaoTask', default: null }) // Referenciando o schema de avaliação
  avaliacaoId?: Types.ObjectId;

  @Prop({ type: String, required: true, default: 'todo' })
  kanbanColumnId: string;

  @Prop({ type: Number, required: true, default: 0 })
  orderInColumn: number;

  @Prop({ default: false })
  recebidaPeloAtribuido?: boolean;
}

export const TaskSchema = SchemaFactory.createForClass(Task);
