"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.FirebaseAuthModule = void 0;
const common_1 = require("@nestjs/common");
const firebase_auth_service_1 = require("./firebase-auth.service");
const firebase_auth_controller_1 = require("./firebase-auth.controller");
const mongoose_1 = require("@nestjs/mongoose");
const admin = require("firebase-admin");
const dotenv = require("dotenv");
const usuario_schema_1 = require("../src/schema/usuario.schema");
dotenv.config();
let FirebaseAuthModule = class FirebaseAuthModule {
};
exports.FirebaseAuthModule = FirebaseAuthModule;
exports.FirebaseAuthModule = FirebaseAuthModule = __decorate([
    (0, common_1.Module)({
        imports: [
            mongoose_1.MongooseModule.forFeature([{ name: usuario_schema_1.User.name, schema: usuario_schema_1.UserSchema }]),
        ],
        controllers: [firebase_auth_controller_1.AuthController],
        providers: [
            firebase_auth_service_1.AuthService,
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
        exports: ['FIREBASE_ADMIN', firebase_auth_service_1.AuthService],
    })
], FirebaseAuthModule);
//# sourceMappingURL=firebase-auth.module.js.map