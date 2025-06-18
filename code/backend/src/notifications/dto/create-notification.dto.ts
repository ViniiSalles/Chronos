import {
  IsString,
  IsNotEmpty,
  IsMongoId,
  IsBoolean,
  IsOptional,
  IsEnum,
} from 'class-validator';
import { NotificationEventType } from 'src/schema/notificacao.schema';

export class CreateNotificationDto {
  @IsMongoId()
  @IsNotEmpty()
  recipient: string; // ID do usuário que receberá a notificação

  @IsString()
  @IsNotEmpty()
  message: string; // Mensagem da notificação

  @IsEnum(NotificationEventType)
  @IsNotEmpty()
  eventType: NotificationEventType; // Tipo de evento

  @IsMongoId()
  @IsOptional()
  relatedToId?: string; // ID do item relacionado (tarefa, projeto, reunião)

  @IsString()
  @IsOptional()
  relatedToModel?: 'Task' | 'Project' | 'Meeting' | 'User'; // Modelo do item relacionado

  @IsBoolean()
  @IsOptional()
  read?: boolean; // Padrão será false
}
