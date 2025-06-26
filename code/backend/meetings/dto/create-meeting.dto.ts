// src/meetings/dto/create-meeting.dto.ts
import {
  IsString,
  IsNotEmpty,
  IsDateString,
  IsOptional,
  IsMongoId,
  IsArray,
  ArrayMinSize,
  IsEnum,
} from 'class-validator';
import { MeetingType } from 'src/schema/reuniao.schema';

export class CreateMeetingDto {
  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsMongoId()
  @IsNotEmpty()
  project: string; // ID do projeto

  // scurmMaster será obtido do token, não passado no body
  // @IsMongoId()
  // @IsNotEmpty()
  // scrumMaster: string;

  @IsDateString()
  @IsNotEmpty()
  startTime: string; // Formato ISO 8601 string (ex: "2025-06-10T10:00:00.000Z")

  @IsDateString()
  @IsNotEmpty()
  endTime: string; // Formato ISO 8601 string

  @IsString()
  @IsOptional()
  location?: string; // Local ou link da reunião

  @IsEnum(MeetingType)
  @IsOptional()
  type?: MeetingType; // Tipo de reunião

  @IsArray()
  @IsMongoId({ each: true })
  @ArrayMinSize(1) // Pelo menos um participante (o próprio SM pode ser o primeiro)
  @IsNotEmpty({ each: true })
  participants: string[]; // IDs dos usuários participantes

  @IsString()
  @IsOptional()
  minutes?: string; // Ata da reunião
}
