// src/auth/auth.service.ts
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User } from 'src/schema/usuario.schema';
import * as bcrypt from 'bcryptjs';

@Injectable()
export class AuthService {
  constructor(@InjectModel(User.name) private userModel: Model<User>) {}

  async syncUserWithFirebase(firebaseUser: any) {
    const { uid, email, name, picture } = firebaseUser;

    let user = await this.userModel.findOne({ email });

    if (!user) {
      const senhaFake = uid + Date.now(); // valor único
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
}
