import { forwardRef, Module } from '@nestjs/common';
import { TaskService } from './task.service';
import { TaskController } from './task.controller';
import { MongooseModule } from '@nestjs/mongoose';
import { TaskSchema } from 'src/schema/tarefa.schema';
import { Task } from './entities/task.entity';
import { UserModule } from 'src/user/user.module'; // Import UserModule
import { ProjectModule } from 'src/project/project.module';
import { Project, ProjectSchema } from 'src/schema/projeto.schema';
import { TaskUser, TaskUserSchema } from 'src/schema/tarefa-usuario.schema';
import { User, UserSchema } from 'src/schema/usuario.schema';
import { FirebaseAuthModule } from 'auth/firebase-auth.module';
import {
  AvaliacaoTask,
  AvaliacaoTaskSchema,
} from 'src/schema/avaliacao-tarefa.schema';
import { NotificationsModule } from 'src/notifications/notifications.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Task.name, schema: TaskSchema },
      { name: TaskUser.name, schema: TaskUserSchema },
      { name: Project.name, schema: ProjectSchema }, // se necessário
      { name: User.name, schema: UserSchema },
      { name: AvaliacaoTask.name, schema: AvaliacaoTaskSchema },
    ]),
    forwardRef(() => ProjectModule),
    forwardRef(() => UserModule),
    FirebaseAuthModule,
    NotificationsModule,
  ],
  controllers: [TaskController],
  providers: [TaskService],
  exports: [
    TaskService,
    MongooseModule.forFeature([{ name: Task.name, schema: TaskSchema }]),
  ],
})
export class TaskModule {}
