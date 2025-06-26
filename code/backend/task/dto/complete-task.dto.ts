// src/tasks/dto/complete-task.dto.ts
import { IsString, IsNotEmpty, IsNumber, IsOptional } from 'class-validator';

export class CompleteTaskDto {
  @IsString()
  @IsNotEmpty()
  userId: string;

  @IsNumber()
  @IsNotEmpty()
  tempo_gasto_horas: number;

  @IsString()
  @IsOptional() // O código pode ser opcional se nem toda conclusão tiver um código associado imediatamente.
  code?: string;
}
