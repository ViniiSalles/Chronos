// src/kanban/schemas/kanban-board.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { KanbanColumnSchema, KanbanColumn } from './kanban-column.schema';

export type KanbanBoardDocument = KanbanBoard & Document;

@Schema({ timestamps: true })
export class KanbanBoard {
  @Prop({
    type: String,
    unique: true,
    default: () => new Types.ObjectId().toHexString(),
  })
  @Prop({ type: Types.ObjectId, ref: 'Project', unique: true, required: true })
  project: Types.ObjectId; // Relacionamento 1:1 com Project

  @Prop({ type: [KanbanColumnSchema], default: [] }) // Array de colunas personalizadas
  columns: KanbanColumn[];

  // Mapeamento de tarefas para colunas:
  // Não vamos armazenar as tarefas aqui, apenas as referências.
  // Cada tarefa terá um `kanbanColumnId` em seu próprio schema.
}

export const KanbanBoardSchema = SchemaFactory.createForClass(KanbanBoard);

KanbanBoardSchema.virtual('id').get(function () {
  return (this as any)._id.toHexString();
});
KanbanBoardSchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    delete ret.__v;
  },
});
KanbanBoardSchema.set('toObject', { virtuals: true });
