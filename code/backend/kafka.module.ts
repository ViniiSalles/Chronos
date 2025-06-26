import { Module, forwardRef } from '@nestjs/common';
import { ProducerService } from './producer.service';
import { ConsumerService } from './consumer.service';
import { MyGateway } from 'src/gateway/gateway';
import { UserModule } from 'src/user/user.module';

@Module({
  providers: [ProducerService, ConsumerService, MyGateway],
  exports: [ProducerService, ConsumerService],
  imports: [forwardRef(() => UserModule)],
})
export class KafkaModule {}
