import { PartialType } from '@nestjs/mapped-types';
import { CreateKanbanColumnDto } from './create-kanban.dto';

export class UpdateKanbanColumnDto extends PartialType(CreateKanbanColumnDto) {}
