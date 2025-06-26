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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const mongoose_1 = require("@nestjs/mongoose");
const mongoose_2 = require("mongoose");
const usuario_schema_1 = require("../src/schema/usuario.schema");
const bcrypt = require("bcryptjs");
let AuthService = class AuthService {
    constructor(userModel) {
        this.userModel = userModel;
    }
    async syncUserWithFirebase(firebaseUser) {
        const { uid, email, name, picture } = firebaseUser;
        let user = await this.userModel.findOne({ email });
        if (!user) {
            const senhaFake = uid + Date.now();
            const senha_hash = await bcrypt.hash(senhaFake, 10);
            user = new this.userModel({
                nome: name || 'Usuário',
                email,
                senha_hash,
                foto_url: picture,
                ativo: true,
                score: 0,
                firebaseUid: uid,
            });
            await user.save();
        }
        return user;
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, mongoose_1.InjectModel)(usuario_schema_1.User.name)),
    __metadata("design:paramtypes", [mongoose_2.Model])
], AuthService);
//# sourceMappingURL=firebase-auth.service.js.map