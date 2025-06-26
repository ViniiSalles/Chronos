import { Module } from '@nestjs/common';
import { NotificationController } from './notifications.controller';
import { NotificationService } from './notifications.service';
import { MongooseModule } from '@nestjs/mongoose';
import {
  NotificationSchema,
  Notification,
} from 'src/schema/notificacao.schema';
import { FirebaseAuthModule } from 'auth/firebase-auth.module';

@Module({
  controllers: [NotificationController],
  providers: [NotificationService],
  imports: [
    MongooseModule.forFeature([
      { name: Notification.name, schema: NotificationSchema },
    ]),
    FirebaseAuthModule,
  ],
  exports: [NotificationsModule, NotificationService],
})
export class NotificationsModule {}
