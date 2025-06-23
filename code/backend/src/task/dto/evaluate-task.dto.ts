import { IsNotEmpty, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

// Define o formato dos dados para avaliar uma tarefa.
export class EvaluateTaskDto {
    @IsNotEmpty()
    @IsString()
    taskId: string;

    @IsNotEmpty()
    @IsNumber()
    @Min(1)
    @Max(5)
    nota: number;

    @IsOptional()
    @IsString()
    comentario: string;
}
