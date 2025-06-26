import { Module } from '@nestjs/common';
import { MyGateway } from './gateway';
import { UserModule } from 'src/user/user.module';

@Module({
  providers: [MyGateway, UserModule],
  imports: [UserModule],
})
export class GatewayModule {}
