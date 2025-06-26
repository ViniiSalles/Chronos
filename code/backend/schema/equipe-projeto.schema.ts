import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type EquipeProjectDocument = EquipeProject & Document;

@Schema()
export class EquipeProject {
  @Prop({ unique: true, required: true }) id: number;
  @Prop({ required: true }) user_id: number;
  @Prop({ required: true }) project_id: number;
  @Prop({ required: false }) papel_no_project: string;
}

export const EquipeProjectSchema = SchemaFactory.createForClass(EquipeProject);
