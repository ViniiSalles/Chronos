import { Module } from '@nestjs/common';
import { AuthService } from './firebase-auth.service';
import { AuthController } from './firebase-auth.controller';
import { MongooseModule } from '@nestjs/mongoose';
import * as admin from 'firebase-admin';
import * as dotenv from 'dotenv';
import { User, UserSchema } from 'src/schema/usuario.schema';

dotenv.config();

@Module({
  imports: [
    MongooseModule.forFeature([{ name: User.name, schema: UserSchema }]),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    {
      provide: 'FIREBASE_ADMIN',
      useFactory: () => {
        return admin.initializeApp({
          credential: admin.credential.cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          }),
        });
      },
    },
  ],
  exports: ['FIREBASE_ADMIN', AuthService],
})
export class FirebaseAuthModule {}
