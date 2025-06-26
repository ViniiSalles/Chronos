// src/auth/auth.controller.ts
import { Controller, Post, UseGuards, Req } from '@nestjs/common';
import { FirebaseAuthGuard } from './firebase-auth.guard';
import { AuthService } from './firebase-auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @UseGuards(FirebaseAuthGuard)
  @Post()
  async firebaseLogin(@Req() req) {
    const firebaseUser = req.user;
    return this.authService.syncUserWithFirebase(firebaseUser);
  }
}
