import { CanActivate, ExecutionContext } from '@nestjs/common';
import { AuthService } from './firebase-auth.service';
export declare class FirebaseAuthGuard implements CanActivate {
    private readonly firebaseAuthService;
    constructor(firebaseAuthService: AuthService);
    canActivate(context: ExecutionContext): Promise<boolean>;
}
