// src/kanban/kanban.controller.ts
import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Req,
} from '@nestjs/common';
import { KanbanService } from './kanban.service';
import {
  CreateKanbanBoardDto,
  CreateKanbanColumnDto,
  MoveTaskKanbanDto,
} from './dto/create-kanban.dto';
import { UpdateKanbanColumnDto } from './dto/update-kanban.dto';

@Controller('kanban')
export class KanbanController {
  constructor(private readonly kanbanService: KanbanService) {}

  /**
   * POST /kanban
   * Cria um novo quadro Kanban para um projeto.
   * @param createKanbanBoardDto DTO de criação do quadro.
   * @param req O objeto de requisição para obter o usuário logado (Scrum Master).
   * @returns O quadro Kanban criado.
   */
  @Post()
  async createBoard(@Body() createKanbanBoardDto: CreateKanbanBoardDto) {
    // O Scrum Master ID será passado para o service para validação de permissão.
    // Como a segurança está sem guard agora, req.user será undefined.
    // Em produção, adicione @UseGuards(FirebaseAuthGuard) e obtenha req.user?._id.

    return this.kanbanService.createBoard(createKanbanBoardDto);
  }

  /**
   * GET /kanban/:projectId
   * Retorna o quadro Kanban completo de um projeto, incluindo colunas e tarefas.
   * @param projectId O ID do projeto.
   * @returns O quadro Kanban com tarefas agrupadas por coluna.
   */
  @Get(':projectId')
  async getBoard(@Param('projectId') projectId: string) {
    return this.kanbanService.getBoard(projectId);
  }

  /**
   * POST /kanban/:boardId/columns
   * Adiciona uma nova coluna a um quadro Kanban.
   * @param boardId ID do quadro Kanban.
   * @param createKanbanColumnDto DTO de criação da coluna.
   * @param req O objeto de requisição para obter o usuário logado (Scrum Master).
   * @returns O quadro Kanban atualizado.
   */
  @Post(':boardId/columns')
  async createColumn(
    @Param('boardId') boardId: string,
    @Body() createKanbanColumnDto: CreateKanbanColumnDto,
  ) {
    return this.kanbanService.createColumn(boardId, createKanbanColumnDto);
  }

  /**
   * PATCH /kanban/:boardId/columns/:columnId
   * Atualiza uma coluna existente em um quadro Kanban.
   * @param boardId ID do quadro Kanban.
   * @param columnId ID da coluna a ser atualizada.
   * @param updateKanbanColumnDto DTO com os campos a serem atualizados.
   * @param req O objeto de requisição para obter o usuário logado (Scrum Master).
   * @returns O quadro Kanban atualizado.
   */
  @Patch(':boardId/columns/:columnId')
  async updateColumn(
    @Param('boardId') boardId: string,
    @Param('columnId') columnId: string,
    @Body() updateKanbanColumnDto: UpdateKanbanColumnDto,
  ) {
    return this.kanbanService.updateColumn(
      boardId,
      columnId,
      updateKanbanColumnDto,
    );
  }

  /**
   * DELETE /kanban/:boardId/columns/:columnId
   * Remove uma coluna de um quadro Kanban.
   * @param boardId ID do quadro Kanban.
   * @param columnId ID da coluna a ser removida.
   * @param req O objeto de requisição para obter o usuário logado (Scrum Master).
   * @returns O quadro Kanban atualizado.
   */
  @Delete(':boardId/columns/:columnId')
  async deleteColumn(
    @Param('boardId') boardId: string,
    @Param('columnId') columnId: string,
  ) {
    return this.kanbanService.deleteColumn(boardId, columnId);
  }

  /**
   * PATCH /kanban/tasks/:taskId/move
   * Move uma tarefa para uma nova coluna Kanban e ajusta sua ordem.
   * @param taskId ID da tarefa a ser movida.
   * @param moveTaskKanbanDto DTO com a nova coluna e ordem.
   * @param req O objeto de requisição para obter o usuário logado (executor ou SM).
   * @returns A tarefa atualizada.
   */
  @Patch('tasks/:taskId/move')
  async moveTask(
    @Param('taskId') taskId: string,
    @Body() moveTaskKanbanDto: MoveTaskKanbanDto,
    @Req() req: any,
  ) {
    return this.kanbanService.moveTask(taskId, moveTaskKanbanDto);
  }
}
