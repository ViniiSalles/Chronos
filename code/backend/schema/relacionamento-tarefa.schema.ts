import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type RelacionamentoTaskDocument = RelacionamentoTask & Document;

@Schema()
export class RelacionamentoTask {
  @Prop({ unique: true, required: true }) id: number;
  @Prop({ required: true }) task_origem_id: number;
  @Prop({ required: true }) task_relacionada_id: number;
}

export const RelacionamentoTaskSchema =
  SchemaFactory.createForClass(RelacionamentoTask);
