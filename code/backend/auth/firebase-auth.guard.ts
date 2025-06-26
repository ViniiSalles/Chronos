import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { AuthService } from './firebase-auth.service';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  constructor(private readonly firebaseAuthService: AuthService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    // console.log(context)
    const request = context.switchToHttp().getRequest();
    const idToken = request.headers.authorization?.split('Bearer ')[1];

    if (!idToken) {
      throw new UnauthorizedException('Token de autenticação não fornecido.');
    }

    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      if (!decodedToken || !decodedToken.uid) {
        throw new UnauthorizedException(
          'Token inválido ou UID não encontrado.',
        );
      }

      // O método syncUserWithFirebase já busca/cria o usuário no MongoDB e o retorna.
      const mongoUser =
        await this.firebaseAuthService.syncUserWithFirebase(decodedToken);

      if (!mongoUser) {
        // Esta verificação pode ser redundante se syncUserWithFirebase sempre retornar um usuário ou lançar erro.
        throw new UnauthorizedException(
          'Usuário não encontrado no sistema após sincronização com Firebase.',
        );
      }

      // Anexa o usuário do MongoDB (que inclui _id, email, nome, etc.) ao objeto request.
      // Assim, os controllers protegidos por este guard terão acesso a req.user.
      request.user = mongoUser;

      return true;
    } catch (error) {
      console.error('FirebaseAuthGuard - Erro de autenticação:', error.message);
      // Personalize a mensagem de erro ou log conforme necessário
      throw new UnauthorizedException(
        error.message || 'Falha na autenticação via Firebase.',
      );
    }
  }
}
