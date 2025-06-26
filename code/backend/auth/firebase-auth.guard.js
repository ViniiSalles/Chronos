"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.FirebaseAuthGuard = void 0;
const common_1 = require("@nestjs/common");
const firebase_auth_service_1 = require("./firebase-auth.service");
const admin = require("firebase-admin");
let FirebaseAuthGuard = class FirebaseAuthGuard {
    constructor(firebaseAuthService) {
        this.firebaseAuthService = firebaseAuthService;
    }
    async canActivate(context) {
        const request = context.switchToHttp().getRequest();
        const idToken = request.headers.authorization?.split('Bearer ')[1];
        if (!idToken) {
            throw new common_1.UnauthorizedException('Token de autenticação não fornecido.');
        }
        try {
            const decodedToken = await admin.auth().verifyIdToken(idToken);
            if (!decodedToken || !decodedToken.uid) {
                throw new common_1.UnauthorizedException('Token inválido ou UID não encontrado.');
            }
            const mongoUser = await this.firebaseAuthService.syncUserWithFirebase(decodedToken);
            if (!mongoUser) {
                throw new common_1.UnauthorizedException('Usuário não encontrado no sistema após sincronização com Firebase.');
            }
            request.user = mongoUser;
            return true;
        }
        catch (error) {
            console.error('FirebaseAuthGuard - Erro de autenticação:', error.message);
            throw new common_1.UnauthorizedException(error.message || 'Falha na autenticação via Firebase.');
        }
    }
};
exports.FirebaseAuthGuard = FirebaseAuthGuard;
exports.FirebaseAuthGuard = FirebaseAuthGuard = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [firebase_auth_service_1.AuthService])
], FirebaseAuthGuard);
//# sourceMappingURL=firebase-auth.guard.js.map