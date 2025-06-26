// src/meetings/meeting.module.ts
import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { Project, ProjectSchema } from 'src/schema/projeto.schema';
import { Meeting, MeetingSchema } from 'src/schema/reuniao.schema';
import { User, UserSchema } from 'src/schema/usuario.schema';
import { UserModule } from 'src/user/user.module';
import { MeetingController } from './meetings.controller';
import { MeetingService } from './meetings.service';
import { FirebaseAuthModule } from 'auth/firebase-auth.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Meeting.name, schema: MeetingSchema },
      { name: Project.name, schema: ProjectSchema }, // Registrar o modelo de Projeto aqui
      { name: User.name, schema: UserSchema }, // Registrar o modelo de Usuário aqui
    ]),
    forwardRef(() => UserModule), // Usar forwardRef se UserModule tiver dependência cíclica
    FirebaseAuthModule,
  ],
  controllers: [MeetingController],
  providers: [MeetingService],
  exports: [MeetingService],
})
export class MeetingModule {}
