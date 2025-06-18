import {
  Injectable,
  Logger,
  Inject,
  forwardRef,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  KanbanBoard,
  KanbanBoardDocument,
} from 'src/schema/kanban-board.schema';
import { KanbanColumn } from 'src/schema/kanban-column.schema';
import { Project, ProjectDocument } from 'src/schema/projeto.schema';
import { Task, TaskDocument } from 'src/schema/tarefa.schema';
import { User, UserDocument } from 'src/schema/usuario.schema';
import { TaskService } from 'src/task/task.service';

import { UpdateKanbanColumnDto } from './dto/update-kanban.dto';
import { NotificationService } from 'src/notifications/notifications.service';
import {
  CreateKanbanBoardDto,
  CreateKanbanColumnDto,
  MoveTaskKanbanDto,
} from './dto/create-kanban.dto';

@Injectable()
export class KanbanService {
  private readonly logger = new Logger(KanbanService.name);

  private readonly defaultColumns: KanbanColumn[] = [
    { id: 'todo', name: 'A Fazer', order: 0, statusMapping: 'pending' },
    {
      id: 'in-progress',
      name: 'Em Andamento',
      order: 1,
      statusMapping: 'in_progress',
    },
    { id: 'done', name: 'Concluído', order: 2, statusMapping: 'done' },
    {
      id: 'cancelled',
      name: 'Cancelado',
      order: 3,
      statusMapping: 'cancelled',
    },
  ];

  constructor(
    @InjectModel(KanbanBoard.name)
    private kanbanBoardModel: Model<KanbanBoardDocument>,
    @InjectModel(Project.name) private projectModel: Model<ProjectDocument>,
    @InjectModel(Task.name) private taskModel: Model<TaskDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    private notificationService: NotificationService,
    @Inject(forwardRef(() => TaskService)) private taskService: TaskService,
  ) {}

  async createBoard(
    createKanbanBoardDto: CreateKanbanBoardDto,
  ): Promise<KanbanBoardDocument> {
    const session = await this.kanbanBoardModel.startSession();
    session.startTransaction();
    try {
      const project = await this.projectModel
        .findById(createKanbanBoardDto.projectId)
        .populate('users')
        .session(session)
        .exec();
      if (!project) {
        throw new NotFoundException('Projeto não encontrado.');
      }

      const existingBoard = await this.kanbanBoardModel
        .findOne({ project: project._id })
        .session(session)
        .exec();
      if (existingBoard) {
        throw new BadRequestException(
          'Já existe um quadro Kanban para este projeto.',
        );
      }

      const newBoard = new this.kanbanBoardModel({
        project: project._id,
        columns: this.defaultColumns,
      });

      const savedBoard = await newBoard.save({ session });
      await session.commitTransaction();
      this.logger.log(`Quadro Kanban criado para o projeto ${project.nome}.`);
      return savedBoard;
    } catch (error) {
      await session.abortTransaction();
      this.logger.error(
        `Erro ao criar quadro Kanban: ${error.message}`,
        error.stack,
      );
      throw error;
    } finally {
      session.endSession();
    }
  }

  async getBoard(projectId: string): Promise<any> {
    if (!Types.ObjectId.isValid(projectId)) {
      throw new BadRequestException('ID de projeto inválido.');
    }

    const board = await this.kanbanBoardModel
      .findOne({ project: projectId })
      .populate('project')
      .exec();

    if (!board) {
      throw new NotFoundException(
        'Quadro Kanban não encontrado para este projeto.',
      );
    }

    const tasks = await this.taskModel
      .find({ projeto: projectId })
      .populate('atribuicoes criadaPor aprovadaPor')
      .exec();

    const columnsWithTasks: any = {};
    board.columns.forEach((column) => {
      columnsWithTasks[column.id] = {
        id: column.id,
        name: column.name,
        order: column.order,
        statusMapping: column.statusMapping,
        tasks: [],
      };
    });

    tasks.forEach((task) => {
      const columnId = task.kanbanColumnId;
      if (columnsWithTasks[columnId]) {
        columnsWithTasks[columnId].tasks.push({
          id: task._id.toString(),
          titulo: task.titulo,
          descricao: task.descricao,
          status: task.status,
          prioridade: task.prioridade,
          complexidade: task.complexidade,
          dataLimite: task.dataLimite,
          kanbanColumnId: task.kanbanColumnId,
          orderInColumn: task.orderInColumn,
          assignedToUsers: task.atribuicoes.map((u: any) => ({
            id: u?._id?.toString() ?? '', // CORREÇÃO: u pode ser null/undefined aqui se populate falhou
            nome: u?.nome ?? 'Usuário Desconhecido',
          })),
          createdByUser: task.criadaPor
            ? {
                id: (task.criadaPor as any)?._id?.toString() ?? '', // CORREÇÃO: ?._id
                nome: (task.criadaPor as any)?.nome ?? 'Usuário Desconhecido',
              }
            : null,
          aprovadoByUser: task.aprovadaPor
            ? {
                id: (task.aprovadaPor as any)?._id?.toString() ?? '', // CORREÇÃO: ?._id
                nome: (task.aprovadaPor as any)?.nome ?? 'Usuário Desconhecido',
              }
            : null,
          recebidaPeloAtribuido: task.recebidaPeloAtribuido,
        });
      } else {
        this.logger.warn(
          `Tarefa ${task._id} referencia coluna Kanban desconhecida: ${columnId}`,
        );
      }
    });

    Object.keys(columnsWithTasks).forEach((colId) => {
      columnsWithTasks[colId].tasks.sort(
        (a: any, b: any) => a.orderInColumn - b.orderInColumn,
      );
    });

    const orderedColumns = Object.values(columnsWithTasks).sort(
      (a: any, b: any) => a.order - b.order,
    );

    return {
      id: board._id.toString(),
      projectId: board.project.toString(),
      projectName: (board.project as unknown as ProjectDocument).nome,
      columns: orderedColumns,
    };
  }

  async createColumn(
    boardId: string,
    createKanbanColumnDto: CreateKanbanColumnDto,
  ): Promise<KanbanBoardDocument> {
    const session = await this.kanbanBoardModel.startSession();
    session.startTransaction();
    try {
      const board = await this.kanbanBoardModel
        .findById(boardId)
        .populate('project.users')
        .session(session)
        .exec();
      if (!board) {
        throw new NotFoundException('Quadro Kanban não encontrado.');
      }

      if (board.columns.some((c) => c.id === createKanbanColumnDto.id)) {
        throw new BadRequestException(
          `Coluna com ID "${createKanbanColumnDto.id}" já existe.`,
        );
      }

      const newColumn: KanbanColumn = {
        id: createKanbanColumnDto.id,
        name: createKanbanColumnDto.name,
        order: createKanbanColumnDto.order ?? board.columns.length,
        statusMapping: createKanbanColumnDto.statusMapping ?? 'custom',
      };

      board.columns.push(newColumn);
      board.columns.sort((a, b) => a.order - b.order);
      const updatedBoard = await board.save({ session });

      await session.commitTransaction();
      this.logger.log(
        `Coluna "${newColumn.name}" adicionada ao quadro ${boardId}.`,
      );
      return updatedBoard;
    } catch (error) {
      await session.abortTransaction();
      this.logger.error(
        `Erro ao criar coluna no quadro ${boardId}: ${error.message}`,
        error.stack,
      );
      throw error;
    } finally {
      session.endSession();
    }
  }

  async updateColumn(
    boardId: string,
    columnId: string,
    updateKanbanColumnDto: UpdateKanbanColumnDto,
  ): Promise<KanbanBoardDocument> {
    const session = await this.kanbanBoardModel.startSession();
    session.startTransaction();
    try {
      const board = await this.kanbanBoardModel
        .findById(boardId)
        .populate('project.users')
        .session(session)
        .exec();
      if (!board) {
        throw new NotFoundException('Quadro Kanban não encontrado.');
      }

      const columnToUpdate = board.columns.find((c) => c.id === columnId);
      if (!columnToUpdate) {
        throw new NotFoundException(
          `Coluna com ID "${columnId}" não encontrada.`,
        );
      }

      Object.assign(columnToUpdate, updateKanbanColumnDto);

      board.columns.sort((a, b) => a.order - b.order);
      const updatedBoard = await board.save({ session });

      await session.commitTransaction();
      this.logger.log(
        `Coluna "${columnToUpdate.name}" atualizada no quadro ${boardId}.`,
      );
      return updatedBoard;
    } catch (error) {
      await session.abortTransaction();
      this.logger.error(
        `Erro ao atualizar coluna ${columnId} no quadro ${boardId}: ${error.message}`,
        error.stack,
      );
      throw error;
    } finally {
      session.endSession();
    }
  }

  async deleteColumn(
    boardId: string,
    columnId: string,
  ): Promise<KanbanBoardDocument> {
    const session = await this.kanbanBoardModel.startSession();
    session.startTransaction();
    try {
      const board = await this.kanbanBoardModel
        .findById(boardId)
        .populate('project.users')
        .session(session)
        .exec();
      if (!board) {
        throw new NotFoundException('Quadro Kanban não encontrado.');
      }

      const tasksInColumn = await this.taskModel
        .find({ kanbanColumnId: columnId })
        .session(session)
        .exec();
      if (tasksInColumn.length > 0) {
        throw new BadRequestException(
          `Não é possível deletar a coluna "${columnId}" porque ela contém ${tasksInColumn.length} tarefas. Mova-as primeiro.`,
        );
      }

      board.columns = board.columns.filter((c) => c.id !== columnId);
      const updatedBoard = await board.save({ session });

      await session.commitTransaction();
      this.logger.log(`Coluna "${columnId}" removida do quadro ${boardId}.`);
      return updatedBoard;
    } catch (error) {
      await session.abortTransaction();
      this.logger.error(
        `Erro ao deletar coluna ${columnId}: ${error.message}`,
        error.stack,
      );
      throw error;
    } finally {
      session.endSession();
    }
  }

  async moveTask(
    taskId: string,
    moveTaskKanbanDto: MoveTaskKanbanDto,
  ): Promise<TaskDocument> {
    const session = await this.taskModel.startSession();
    session.startTransaction();
    try {
      const task = await this.taskModel
        .findById(taskId)
        .populate('projeto atribuicoes criadaPor')
        .session(session)
        .exec();
      if (!task) {
        throw new NotFoundException('Tarefa não encontrada.');
      }

      const project = task.projeto as unknown as ProjectDocument;

      const board = await this.kanbanBoardModel
        .findOne({ project: project._id })
        .session(session)
        .exec();
      if (!board) {
        throw new NotFoundException(
          'Quadro Kanban não encontrado para o projeto da tarefa.',
        );
      }

      const targetColumn = board.columns.find(
        (c) => c.id === moveTaskKanbanDto.newColumnId,
      );
      if (!targetColumn) {
        throw new BadRequestException(
          `Coluna de destino "${moveTaskKanbanDto.newColumnId}" não encontrada no quadro Kanban.`,
        );
      }

      const oldColumnId = task.kanbanColumnId;
      const oldOrder = task.orderInColumn;
      const oldStatus = task.status;

      task.kanbanColumnId = moveTaskKanbanDto.newColumnId;
      task.orderInColumn = moveTaskKanbanDto.newOrder;

      if (
        targetColumn.statusMapping &&
        targetColumn.statusMapping !== 'custom'
      ) {
        task.status = targetColumn.statusMapping;
      }

      if (task.status === 'done' && oldStatus !== 'done') {
        task.dataConclusao = new Date();
      }

      const updatedTask = await task.save({ session });

      // 3. Ajustar ordens nas colunas afetadas
      if (oldColumnId === moveTaskKanbanDto.newColumnId) {
        await this.reindexColumn(
          board.project.toString(),
          oldColumnId,
          updatedTask._id.toString(),
          moveTaskKanbanDto.newOrder,
          oldOrder,
          session,
          oldColumnId,
          moveTaskKanbanDto.newColumnId,
        );
      } else {
        await this.reindexColumn(
          board.project.toString(),
          oldColumnId,
          updatedTask._id.toString(),
          -1,
          oldOrder,
          session,
          oldColumnId,
          moveTaskKanbanDto.newColumnId,
        );
        await this.reindexColumn(
          board.project.toString(),
          moveTaskKanbanDto.newColumnId,
          updatedTask._id.toString(),
          moveTaskKanbanDto.newOrder,
          -1,
          session,
          oldColumnId,
          moveTaskKanbanDto.newColumnId,
        );
      }

      await session.commitTransaction();
      return updatedTask;
    } catch (error) {
      await session.abortTransaction();
      this.logger.error(
        `Erro ao mover tarefa ${taskId}: ${error.message}`,
        error.stack,
      );
      throw error;
    } finally {
      session.endSession();
    }
  }

  private async reindexColumn(
    projectId: string,
    columnId: string,
    movedTaskId: string,
    newOrder: number,
    oldOrder: number,
    session: any,
    oldColumnId?: string,
    newColumnId?: string,
  ): Promise<void> {
    const tasksToReindex = await this.taskModel
      .find({
        projeto: projectId,
        kanbanColumnId: columnId,
        _id: { $ne: new Types.ObjectId(movedTaskId) },
      })
      .sort({ orderInColumn: 1 })
      .session(session)
      .exec();

    const tasksInNewOrder: TaskDocument[] = [];
    let currentOrder = 0;
    let movedTaskAdded = false;

    if (oldColumnId && oldColumnId === columnId && newOrder !== -1) {
      for (const task of tasksToReindex) {
        if (currentOrder === newOrder && !movedTaskAdded) {
          const movedTask = await this.taskModel
            .findById(movedTaskId)
            .session(session)
            .exec();
          if (movedTask) {
            tasksInNewOrder.push(movedTask);
            movedTaskAdded = true;
          }
        }
        tasksInNewOrder.push(task);
        currentOrder++;
      }
      if (currentOrder === newOrder && !movedTaskAdded) {
        const movedTask = await this.taskModel
          .findById(movedTaskId)
          .session(session)
          .exec();
        if (movedTask) {
          tasksInNewOrder.push(movedTask);
        }
      }
    } else if (newOrder !== -1 && newColumnId && columnId === newColumnId) {
      for (const task of tasksToReindex) {
        if (currentOrder === newOrder && !movedTaskAdded) {
          const movedTask = await this.taskModel
            .findById(movedTaskId)
            .session(session)
            .exec();
          if (movedTask) {
            tasksInNewOrder.push(movedTask);
            movedTaskAdded = true;
          }
        }
        tasksInNewOrder.push(task);
        currentOrder++;
      }
      if (currentOrder === newOrder && !movedTaskAdded) {
        const movedTask = await this.taskModel
          .findById(movedTaskId)
          .session(session)
          .exec();
        if (movedTask) {
          tasksInNewOrder.push(movedTask);
        }
      }
    } else if (oldOrder !== -1 && oldColumnId && columnId === oldColumnId) {
      tasksToReindex.forEach((task) => tasksInNewOrder.push(task));
    }

    let orderCounter = 0;
    for (const task of tasksInNewOrder) {
      if (task.orderInColumn !== orderCounter) {
        task.orderInColumn = orderCounter;
        await task.save({ session });
      }
      orderCounter++;
    }

    this.logger.log(
      `Coluna ${columnId} reindexada no projeto ${projectId}. Total de tarefas: ${tasksInNewOrder.length}.`,
    );
  }
}
