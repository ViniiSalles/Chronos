import { forwardRef, Module } from '@nestjs/common';
import { UserService } from './user.service';
import { UserController } from './user.controller';
import { MongooseModule } from '@nestjs/mongoose';
import { User, UserSchema } from 'src/schema/usuario.schema';
import { ProjectModule } from 'src/project/project.module';
import { TaskModule } from 'src/task/task.module';
import { FirebaseAuthModule } from '../../auth/firebase-auth.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      {
        name: User.name,
        schema: UserSchema,
      },
    ]),
    forwardRef(() => ProjectModule),
    forwardRef(() => TaskModule),
    FirebaseAuthModule
  ],
  controllers: [UserController],
  providers: [UserService], // Remove ProjectModule, TaskModule
  exports: [UserService],
})
export class UserModule { }
