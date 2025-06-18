// src/kanban/schemas/kanban-column.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type KanbanColumnDocument = KanbanColumn & Document;

@Schema({ _id: false }) // Não cria _id para subdocumentos se não for necessário, mas se for array root, pode ter
export class KanbanColumn {
  @Prop({ type: String, required: true }) // ID da coluna Kanban
  id: string; // Ex: "todo", "in-progress", "in-review", "custom-column-id"

  @Prop({ required: true })
  name: string; // Nome da coluna (ex: "A Fazer", "Em Revisão")

  @Prop({ required: true, default: 0 })
  order: number; // Ordem da coluna dentro do quadro Kanban

  @Prop({
    type: String,
    enum: ['pending', 'in_progress', 'done', 'cancelled', 'custom'],
    required: true,
  })
  // Mapeamento interno para status de tarefa. 'custom' para colunas criadas pelo usuário.
  // Uma coluna "Em Revisão" pode mapear para status 'in_progress' ou um novo 'review'
  // Se 'custom', o status real da tarefa pode ser 'in_progress' ou outro.
  statusMapping: string; // Status da tarefa que esta coluna representa (para colunas padrão)
  // ou um identificador 'custom' para colunas adicionais.
}

export const KanbanColumnSchema = SchemaFactory.createForClass(KanbanColumn);
