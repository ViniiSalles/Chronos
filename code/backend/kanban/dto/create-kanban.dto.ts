// src/kanban/dto/create-kanban-board.dto.ts
import {
  IsMongoId,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

export class CreateKanbanBoardDto {
  @IsMongoId()
  @IsNotEmpty()
  projectId: string; // ID do projeto ao qual este quadro Kanban pertence
}

export class CreateKanbanColumnDto {
  @IsString()
  @IsNotEmpty()
  id: string; // ID único da coluna (ex: 'custom-dev-queue')

  @IsString()
  @IsNotEmpty()
  name: string; // Nome visível da coluna (ex: 'Fila de Desenvolvimento')

  @IsNumber()
  @IsOptional()
  order?: number; // Ordem da coluna, se não for fornecido, o serviço definirá

  @IsString() // Aqui você pode usar string diretamente, ou um enum mais específico para colunas customizadas
  @IsOptional()
  // Exemplo se você tiver um enum customizado ou usar strings literais permitidas:
  // @IsEnum(['pending', 'in_progress', 'done', 'cancelled', 'custom'])
  statusMapping?: string; // Mapeamento de status (ex: 'pending', 'in_progress', 'done', 'custom')
}

export class MoveTaskKanbanDto {
  @IsString()
  @IsNotEmpty()
  newColumnId: string; // ID da coluna de destino

  @IsNumber()
  @IsNotEmpty()
  newOrder: number; // Nova ordem da tarefa dentro da coluna de destino
}
