// src/meetings/schemas/meeting.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type MeetingDocument = Meeting & Document;

// Opcional: Enum para tipos de reunião, se quiser categorizar
export enum MeetingType {
  DAILY_SCRUM = 'Daily Scrum',
  SPRINT_PLANNING = 'Sprint Planning',
  SPRINT_REVIEW = 'Sprint Review',
  SPRINT_RETROSPECTIVE = 'Sprint Retrospective',
  REFINEMENT = 'Refinement',
  OTHER = 'Other',
}

@Schema({ timestamps: true }) // Adiciona createdAt e updatedAt automaticamente
export class Meeting {

  @Prop({ required: true })
  title: string; // Título ou assunto da reunião

  @Prop()
  description?: string; // Descrição ou pauta da reunião

  @Prop({ type: Types.ObjectId, ref: 'Project', required: true })
  project: Types.ObjectId; // Projeto ao qual a reunião pertence

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  scrumMaster: Types.ObjectId; // ID do Scrum Master que criou/gerencia a reunião

  @Prop({ required: true })
  startTime: Date; // Data e hora de início da reunião

  @Prop({ required: true })
  endTime: Date; // Data e hora de término da reunião

  @Prop()
  location?: string; // Local físico ou link da ferramenta de reunião (ex: Zoom, Google Meet)

  @Prop({ enum: MeetingType, default: MeetingType.OTHER })
  type: MeetingType; // Tipo de reunião (Daily, Planning, etc.)

  @Prop([
    {
      user: { type: Types.ObjectId, ref: 'User', required: true },
    },
  ])
  participants: Array<{ user: Types.ObjectId }>; // Lista de participantes (apenas IDs por enquanto)

  @Prop()
  minutes?: string; // Ata da reunião (resumo, decisões, etc.)
}

export const MeetingSchema = SchemaFactory.createForClass(Meeting);

MeetingSchema.set('toObject', { virtuals: true });
