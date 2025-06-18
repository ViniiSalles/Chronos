import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ProjectDocument = Project & Document;

@Schema()
export class Project extends Document {
  @Prop({ required: true })
  nome: string;

  @Prop()
  descricao: string;

  @Prop({ type: Date })
  dataInicio: Date;

  @Prop({ type: Date })
  data_fim: Date;

  @Prop({ default: 'ativo' })
  status: string;

  @Prop({
    type: [
      {
        id: String,
        nome: String,
        email: String,
        papel: String,
      },
    ],
    default: [],
  })
  users: {
    id: string;
    nome: string;
    email: string;
    papel: string;
  }[];

  // CORREÇÃO AQUI: O array 'tasks' agora armazena apenas ObjectIds que referenciam a Task
  @Prop({ type: [{ type: Types.ObjectId, ref: 'Task' }], default: [] })
  tasks: Types.ObjectId[]; // Apenas um array de IDs de tarefas
}

export const ProjectSchema = SchemaFactory.createForClass(Project);
