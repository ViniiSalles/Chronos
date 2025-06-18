import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { Complexidade } from 'src/types/types';
import { v4 as uuidv4 } from 'uuid';

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

  // Sua declaração atual já é a forma correta de ter apenas o ID do projeto.
  // 'projeto' é um ObjectId que faz referência ao documento 'Project'.
  @Prop({ type: Types.ObjectId, ref: 'Project', required: true })
  projeto: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  criadaPor: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  aprovadaPor?: Types.ObjectId;

  @Prop([{ type: Types.ObjectId, ref: 'User' }])
  atribuicoes?: Types.ObjectId[];

  @Prop({ type: [{ type: Types.ObjectId, ref: 'Task' }], default: [] })
  tarefasAnteriores: Types.ObjectId[];

  @Prop({ type: Types.ObjectId, ref: 'TaskReview', default: null })
  avaliacaoId?: Types.ObjectId;

  // NOVO CAMPO: ID da coluna Kanban à qual a tarefa pertence
  @Prop({ type: String, required: true, default: 'todo' }) // ID da coluna (ex: "todo", "in-progress", "custom-column-id")
  kanbanColumnId: string;

  // NOVO CAMPO: Ordem da tarefa dentro da coluna Kanban
  @Prop({ required: true, default: 0 })
  orderInColumn: number;

  @Prop({ default: false })
  recebidaPeloAtribuido?: boolean;
}

export const TaskSchema = SchemaFactory.createForClass(Task);
