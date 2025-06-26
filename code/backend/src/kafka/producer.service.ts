import { Injectable, OnModuleInit } from '@nestjs/common';
import { Kafka, Producer, ProducerRecord } from 'kafkajs';
import * as dotenv from 'dotenv';

dotenv.config();


@Injectable()
export class ProducerService implements OnModuleInit {
  private readonly kafka = new Kafka({
    brokers: [process.env.BROKERS ?? 'localhost:9092'],
  });
  private readonly producer: Producer = this.kafka.producer();

  async onModuleInit() {
    await this.producer.connect();
  }

  async produce(record: ProducerRecord) {
    await this.producer.send(record);
  }

  async onApplicationShutdown() {
    await this.producer.disconnect();
  }
}
