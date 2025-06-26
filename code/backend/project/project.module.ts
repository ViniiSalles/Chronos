import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ProjectService } from './project.service';
import { ProjectController } from './project.controller';
import { Project, ProjectSchema } from '../schema/projeto.schema';
import { User, UserSchema } from '../schema/usuario.schema';
import { Task, TaskSchema } from '../schema/tarefa.schema';
import { TaskUser, TaskUserSchema } from '../schema/tarefa-usuario.schema';
import { UserModule } from '../user/user.module';
import { FirebaseAuthModule } from '../../auth/firebase-auth.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Project.name, schema: ProjectSchema },
      { name: User.name, schema: UserSchema },
      { name: Task.name, schema: TaskSchema },
      { name: TaskUser.name, schema: TaskUserSchema },
    ]),
    forwardRef(() => UserModule),
    FirebaseAuthModule,
  ],
  controllers: [ProjectController],
  providers: [ProjectService],
  exports: [ProjectService],
})
export class ProjectModule { }
