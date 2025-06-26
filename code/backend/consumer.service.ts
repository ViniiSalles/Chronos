import {
  Injectable,
  OnApplicationShutdown,
  OnModuleInit,
} from '@nestjs/common';
import {
  Consumer,
  ConsumerRunConfig,
  ConsumerSubscribeTopic,
  Kafka,
} from 'kafkajs';
import { MyGateway } from 'src/gateway/gateway';

@Injectable()
export class ConsumerService implements OnApplicationShutdown, OnModuleInit {
  private readonly kafka = new Kafka({
    brokers: [process.env.BROKERS ?? 'localhost:9092'],
  });
  private readonly consumers: Consumer[] = [];

  constructor(private readonly gateway: MyGateway) {}

  async onModuleInit() {
    await this.consume(
      { topic: 'task.created' },
      {
        eachMessage: async () => {
          // A lógica de eachMessage está no método consume
        },
      },
    );
  }

  async consume(topic: ConsumerSubscribeTopic, config: ConsumerRunConfig) {
    const consumer = this.kafka.consumer({ groupId: 'nestjs-kafka' });
    await consumer.connect();
    await consumer.subscribe(topic);
    await consumer.run({
      ...config,
      eachMessage: async (payload) => {
        const { message } = payload;
        const task = JSON.parse(message.value.toString());
        // Emitir a mensagem apenas para os usuários em atribuicoes
        if (task.atribuicoes && Array.isArray(task.atribuicoes)) {
          this.gateway.emitToUsers(task.atribuicoes, 'taskCreated', {
            msg: 'New Task Created',
            content: task,
          });
        }
        if (config.eachMessage) {
          await config.eachMessage(payload);
        }
      },
    });
    this.consumers.push(consumer);
  }

  async onApplicationShutdown() {
    for (const consumer of this.consumers) {
      await consumer.disconnect();
    }
  }
}
