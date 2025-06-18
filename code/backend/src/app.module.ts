import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { MongooseModule } from '@nestjs/mongoose';
import { ProjectModule } from './project/project.module';
import { TaskModule } from './task/task.module';
import { UserModule } from './user/user.module';
import { ConfigModule } from '@nestjs/config';
import { FirebaseAuthModule } from 'auth/firebase-auth.module';
// import { KafkaModule } from './kafka/kafka.module';
// import { TestConsumer } from './test.consumer';
import { MeetingModule } from './meetings/meetings.module';
import { NotificationsModule } from './notifications/notifications.module';
import { KanbanModule } from './kanban/kanban.module';

@Module({
  imports: [
    ConfigModule.forRoot(),
    MongooseModule.forRoot(process.env.MONGODB_URI),
    ProjectModule,
    TaskModule,
    UserModule,
    FirebaseAuthModule,
    MeetingModule,
    NotificationsModule,
    KanbanModule,
    //KafkaModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    //TestConsumer
  ],
})
export class AppModule {}
