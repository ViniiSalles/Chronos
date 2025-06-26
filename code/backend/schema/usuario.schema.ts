import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type UserDocument = User & Document;

@Schema()
export class User extends Document {
  @Prop({ required: true })
  nome: string;

  @Prop({ required: true, unique: true })
  email: string;

  @Prop({ required: true })
  senha_hash: string;

  @Prop()
  foto_url?: string;

  @Prop({ default: true })
  ativo: boolean;

  @Prop({ default: 0 })
  score: number;

  @Prop({
    type: {
      tarefasConcluidas: Number,
      mediaNotas: Number,
      totalAvaliacoes: Number,
      tarefasAvaliadas: Number,
      totalPontosRecebidos: Number,
      tempoMedioConclusao: Number,
      ultimaConclusao: Date,
      ultimaAvaliacao: Date,
    },
    default: {
      tarefasConcluidas: 0,
      mediaNotas: 0,
      totalAvaliacoes: 0,
      tarefasAvaliadas: 0,
      totalPontosRecebidos: 0,
      tempoMedioConclusao: 0,
      ultimaConclusao: null,
      ultimaAvaliacao: null,
    },
  })
  statistics: {
    tarefasConcluidas: number;
    mediaNotas: number;
    totalAvaliacoes: number;
    tarefasAvaliadas: number;
    totalPontosRecebidos: number;
    tempoMedioConclusao?: number;
    ultimaConclusao?: Date;
    ultimaAvaliacao?: Date;
  };

  @Prop({ unique: true, required: true, index: true })
  firebaseUid: string;
}

export const UserSchema = SchemaFactory.createForClass(User);
