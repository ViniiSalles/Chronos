import {
  Injectable,
  Inject,
  forwardRef,
  NotFoundException,
  BadRequestException,
  Logger,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskDto } from './dto/update-task.dto';
import { Project, ProjectDocument } from 'src/schema/projeto.schema';
import { TaskUser, TaskUserDocument } from 'src/schema/tarefa-usuario.schema';
import { Task, TaskDocument } from 'src/schema/tarefa.schema';
import { UserService } from 'src/user/user.service';
import { Complexidade } from 'src/types/types';
import { User, UserDocument } from 'src/schema/usuario.schema';
import { ProducerService } from 'src/kafka/producer.service';
import {
  AvaliacaoTask,
  AvaliacaoTaskDocument,
} from 'src/schema/avaliacao-tarefa.schema';
import { NotificationService } from 'src/notifications/notifications.service';
import { NotificationEventType } from 'src/schema/notificacao.schema';
import { EvaluateTaskDto } from './dto/evaluate-task.dto';

@Injectable()
export class TaskService {
  private readonly logger = new Logger(TaskService.name);

  constructor(
    @InjectModel(Task.name) private taskModel: Model<TaskDocument>,
    @InjectModel(Project.name) private projectModel: Model<ProjectDocument>,
    @InjectModel(TaskUser.name) private taskUserModel: Model<TaskUserDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(AvaliacaoTask.name)
    private avaliacaoTaskModel: Model<AvaliacaoTaskDocument>,
    @Inject(forwardRef(() => UserService)) private userService: UserService,
    private readonly producerService: ProducerService,
    @Inject(forwardRef(() => NotificationService))
    private notificationService: NotificationService,
  ) {}

  async create(
    createTaskDto: CreateTaskDto,
    creatorUserId: string,
  ): Promise<Task> {
    const session = await this.taskModel.startSession();
    session.startTransaction();
    try {
      const project = await this.projectModel
        .findById(createTaskDto.projeto)
        .session(session)
        .exec();
      if (!project) throw new NotFoundException('Projeto não encontrado');

      const creator = await this.userService.findOne(creatorUserId);
      if (!creator)
        throw new NotFoundException(
          'Usuário criador não encontrado (baseado no token)',
        );

      const creatorInProject = project.users.some(
        (u) => u.id.toString() === creatorUserId,
      );
      if (!creatorInProject) {
        throw new BadRequestException(
          'Usuário criador não faz parte do projeto. Apenas membros do projeto podem criar tarefas nele.',
        );
      }

      if (createTaskDto.aprovadaPor) {
        const approver = await this.userService.findOne(
          createTaskDto.aprovadaPor,
        );
        if (!approver)
          throw new NotFoundException('Usuário aprovador não encontrado');

        const approverInProject = project.users.some(
          (u) => u.id.toString() === createTaskDto.aprovadaPor,
        );
        if (!approverInProject) {
          throw new BadRequestException(
            'Usuário aprovador não faz parte do projeto',
          );
        }
      }

      if (createTaskDto.tarefasAnteriores?.length > 0) {
        for (const taskId of createTaskDto.tarefasAnteriores) {
          const exists = await this.taskModel
            .findById(taskId)
            .session(session)
            .exec();
          if (!exists)
            throw new NotFoundException(
              `Tarefa anterior ${taskId} não encontrada`,
            );
        }
      }

      const task = new this.taskModel({
        ...createTaskDto,
        criadaPor: creatorUserId,
      });
      const savedTask = await task.save({ session });

      // Update the project to include the new task's ObjectId
      project.tasks.push(savedTask._id as Types.ObjectId); // Only push the ObjectId
      await project.save({ session });

      await session.commitTransaction();

      await session.commitTransaction();
      console.log('Task created successfully:', savedTask._id.toString());

      try {
        console.log(
          'Sending message to Kafka for task:',
          savedTask._id.toString(),
        );
        await this.producerService.produce({
          topic: 'task.created',
          messages: [
            {
              value: JSON.stringify({
                id: savedTask._id.toString(),
                titulo: savedTask.titulo,
                descricao: savedTask.descricao,
                status: savedTask.status,
                dataInicio: savedTask.dataInicio,
                dataLimite: savedTask.dataLimite,
                complexidade: savedTask.complexidade,
                projeto: savedTask.projeto,
                criadaPor: savedTask.criadaPor,
                atribuicoes: createTaskDto.atribuicoes || [],
              }),
            },
          ],
        });
        console.log('Message sent to Kafka successfully');
      } catch (error) {
        console.error('Error sending message to Kafka:', error);
        throw error; // Opcional: decidir se quer lançar o erro ou apenas logar
      }

      return savedTask;
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }
  async findAll(): Promise<Task[]> {
    return this.taskModel
      .find()
      .populate('projeto criadaPor aprovadaPor atribuicoes')
      .exec();
  }

  async findOne(id: string): Promise<Task> {
    const task = await this.taskModel
      .findById(id)
      .populate('projeto criadaPor aprovadaPor atribuicoes')
      .exec();
    if (!task) throw new NotFoundException('Tarefa não encontrada');
    return task;
  }

  //metódo update corrigido
  async update(id: string, updateTaskDto: UpdateTaskDto): Promise<Task> {
    const session = await this.taskModel.startSession();
    session.startTransaction();
    try {
      const task = await this.taskModel.findById(id).session(session).exec();
      if (!task) throw new NotFoundException('Tarefa não encontrada');

      const oldStatus = task.status;
      const oldAssignedUsers = task.atribuicoes.map((u) => u.toString());

      let project = await this.projectModel
        .findById(task.projeto)
        .session(session)
        .exec();
      if (!project) throw new NotFoundException('Projeto não encontrado');

      if (
        updateTaskDto.projeto &&
        updateTaskDto.projeto !== task.projeto.toString()
      ) {
        project = await this.projectModel
          .findById(updateTaskDto.projeto)
          .session(session)
          .exec();
        if (!project)
          throw new NotFoundException('Novo projeto não encontrado');

        await this.projectModel
          .updateOne(
            { _id: task.projeto },
            { $pull: { tasks: task._id } },
            { session },
          )
          .exec();

        project.tasks.push(task._id as Types.ObjectId);
        await project.save({ session });
      }

      if (updateTaskDto.aprovadaPor) {
        const approver = await this.userService.findOne(
          updateTaskDto.aprovadaPor,
        );
        if (!approver)
          throw new NotFoundException('Usuário aprovador não encontrado');
        const approverInProject = project.users.some(
          (u: any) => u.id.toString() === updateTaskDto.aprovadaPor,
        );
        if (!approverInProject) {
          throw new BadRequestException(
            'Usuário aprovador não faz parte do projeto',
          );
        }
      }

      const updatedTask = await this.taskModel
        .findByIdAndUpdate(id, updateTaskDto, { new: true, session })
        .populate('projeto criadaPor aprovadaPor atribuicoes')
        .exec();

      if (!updatedTask) throw new NotFoundException('Tarefa não encontrada');

      if (updateTaskDto.atribuicoes) {
        await this.taskUserModel
          .deleteMany({ task_id: id })
          .session(session)
          .exec();

        const newAssignedUsers = updatedTask.atribuicoes.map((u) =>
          u.toString(),
        );

        for (const userId of newAssignedUsers) {
          const user = await this.userService.findOne(userId);
          if (!user)
            throw new NotFoundException(`Usuário ${userId} não encontrado`);

          const userInProject = project.users.some(
            (u: any) => u.id.toString() === userId,
          );
          if (!userInProject) {
            throw new BadRequestException(
              `Usuário ${userId} não faz parte do projeto`,
            );
          }
          await this.taskUserModel.create(
            [{ task_id: id, user_id: userId, notificado_relacionada: false }],
            { session },
          );
        }

        const addedUsers = newAssignedUsers.filter(
          (uId) => !oldAssignedUsers.includes(uId),
        );
        const removedUsers = oldAssignedUsers.filter(
          (uId) => !newAssignedUsers.includes(uId),
        );

        for (const userId of addedUsers) {
          const addedUserName =
            (await this.userService.findOne(userId))?.nome ||
            'usuário(a) desconhecido(a)';
          await this.notificationService.createNotification({
            recipient: userId,
            message: `Você foi atribuído à tarefa: "${updatedTask.titulo}".`,
            eventType: NotificationEventType.TASK_UPDATED,
            relatedToId: updatedTask._id.toString(),
            relatedToModel: 'Task',
          });

          const otherRecipients = new Set(oldAssignedUsers);
          if (updatedTask.criadaPor) {
            otherRecipients.add(updatedTask.criadaPor.toString());
          }
          otherRecipients.delete(userId);

          for (const recipientId of otherRecipients) {
            // CORREÇÃO: Usar Types.ObjectId.isValid
            if (!Types.ObjectId.isValid(recipientId)) {
              this.logger.error(
                `ID de recipient inválido para notificação de adição: ${recipientId}`,
              );
              continue;
            }
            await this.notificationService.createNotification({
              recipient: recipientId,
              message: `${addedUserName} foi adicionado à tarefa "${updatedTask.titulo}".`,
              eventType: NotificationEventType.TASK_UPDATED,
              relatedToId: updatedTask._id.toString(),
              relatedToModel: 'Task',
            });
          }
        }

        for (const userId of removedUsers) {
          const removedUserName =
            (await this.userService.findOne(userId))?.nome ||
            'usuário(a) desconhecido(a)';
          await this.notificationService.createNotification({
            recipient: userId,
            message: `Você foi removido da tarefa: "${updatedTask.titulo}".`,
            eventType: NotificationEventType.TASK_UPDATED,
            relatedToId: updatedTask._id.toString(),
            relatedToModel: 'Task',
          });

          const otherRecipients = new Set(newAssignedUsers);
          if (updatedTask.criadaPor) {
            otherRecipients.add(updatedTask.criadaPor.toString());
          }
          otherRecipients.delete(userId);

          for (const recipientId of otherRecipients) {
            // CORREÇÃO: Usar Types.ObjectId.isValid
            if (!Types.ObjectId.isValid(recipientId)) {
              this.logger.error(
                `ID de recipient inválido para notificação de remoção: ${recipientId}`,
              );
              continue;
            }
            await this.notificationService.createNotification({
              recipient: recipientId,
              message: `${removedUserName} foi removido(a) da tarefa "${updatedTask.titulo}".`,
              eventType: NotificationEventType.TASK_UPDATED,
              relatedToId: updatedTask._id.toString(),
              relatedToModel: 'Task',
            });
          }
        }
      }

      const hasContentChanged =
        updatedTask.titulo !== task.titulo ||
        updatedTask.descricao !== task.descricao ||
        updatedTask.dataInicio?.getTime() !== task.dataInicio?.getTime() ||
        updatedTask.dataLimite?.getTime() !== task.dataLimite?.getTime() ||
        updatedTask.complexidade !== task.complexidade ||
        updatedTask.prioridade !== task.prioridade;

      if (updatedTask.status !== oldStatus) {
        const message = `O status da tarefa "${updatedTask.titulo}" mudou para "${updatedTask.status}".`;

        const recipients = new Set(
          updatedTask.atribuicoes.map((u) => u.toString()),
        );
        if (updatedTask.criadaPor) {
          recipients.add(updatedTask.criadaPor.toString());
        }

        for (const recipientId of recipients) {
          // CORREÇÃO: Usar Types.ObjectId.isValid
          if (!Types.ObjectId.isValid(recipientId)) {
            this.logger.error(
              `ID de recipient inválido para notificação de status: ${recipientId}`,
            );
            continue;
          }
          await this.notificationService.createNotification({
            recipient: recipientId,
            message: message,
            eventType: NotificationEventType.TASK_UPDATED,
            relatedToId: updatedTask._id.toString(),
            relatedToModel: 'Task',
          });
        }
      } else if (hasContentChanged) {
        const message = `A tarefa "${updatedTask.titulo}" foi atualizada.`;

        const recipients = new Set(
          updatedTask.atribuicoes.map((u) => u.toString()),
        );
        if (updatedTask.criadaPor) {
          recipients.add(updatedTask.criadaPor.toString());
        }

        for (const recipientId of recipients) {
          // CORREÇÃO: Usar Types.ObjectId.isValid
          if (!Types.ObjectId.isValid(recipientId)) {
            this.logger.error(
              `ID de recipient inválido para notificação de conteúdo: ${recipientId}`,
            );
            continue;
          }
          await this.notificationService.createNotification({
            recipient: recipientId,
            message: message,
            eventType: NotificationEventType.TASK_UPDATED,
            relatedToId: updatedTask._id.toString(),
            relatedToModel: 'Task',
          });
        }
      }

      await session.commitTransaction();
      return updatedTask;
    } catch (error) {
      await session.abortTransaction();
      this.logger.error(
        `Erro ao atualizar tarefa ${id}: ${error.message}`,
        error.stack,
      );
      throw error;
    } finally {
      session.endSession();
    }
  }

  async remove(id: string): Promise<void> {
    const session = await this.taskModel.startSession();
    session.startTransaction();
    try {
      const task = await this.taskModel.findById(id).session(session).exec();
      if (!task) throw new NotFoundException('Tarefa não encontrada');
      await this.taskUserModel
        .deleteMany({ task_id: id })
        .session(session)
        .exec();
      await this.projectModel
        .updateOne(
          { _id: task.projeto },
          { $pull: { tasks: task._id } }, // Remove ObjectId from tasks array
          { session },
        )
        .exec();
      await this.taskModel.findByIdAndDelete(id).session(session).exec();
      await session.commitTransaction();
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }

  async assignUserToTask(taskId: string, userId: string): Promise<TaskUser> {
    const session = await this.taskModel.startSession();
    session.startTransaction();
    try {
      const task = await this.taskModel
        .findById(taskId)
        .session(session)
        .exec();
      if (!task) throw new NotFoundException('Tarefa não encontrada');
      const project = await this.projectModel
        .findById(task.projeto)
        .session(session)
        .exec();
      if (!project) throw new NotFoundException('Projeto não encontrado');
      const user = await this.userService.findOne(userId);
      if (!user) throw new NotFoundException('Usuário não encontrado');
      const userInProject = project.users.some(
        (u) => u.id.toString() === userId,
      );
      if (!userInProject) {
        throw new BadRequestException(
          'Usuário não faz parte do projeto da tarefa',
        );
      }
      const existing = await this.taskUserModel
        .findOne({ task_id: taskId, user_id: userId })
        .session(session)
        .exec();
      if (existing) {
        throw new BadRequestException('Usuário já está atribuído à tarefa');
      }
      await this.taskModel
        .findByIdAndUpdate(
          taskId,
          { $addToSet: { atribuicoes: userId } },
          { session },
        )
        .exec();
      const [taskUser] = await this.taskUserModel.create(
        [{ task_id: taskId, user_id: userId, notificado_relacionada: false }],
        { session },
      );
      await session.commitTransaction();
      return taskUser;
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }

  async completeTask(
    taskId: string,
    userId: string,
    tempo_gasto_horas: number,
    code?: string,
  ): Promise<TaskUser> {
    const session = await this.taskModel.startSession();
    session.startTransaction();
    try {
      const task = await this.taskModel
        .findById(taskId)
        .session(session)
        .exec();
      if (!task) throw new NotFoundException('Tarefa não encontrada');
      const isAssigned = task.atribuicoes
        .map((a) => a.toString())
        .includes(userId);
      if (!isAssigned) {
        throw new BadRequestException(
          'Usuário não está atribuído a esta tarefa',
        );
      }
      if (task.tarefasAnteriores?.length > 0) {
        const incompletas = await this.taskModel
          .find({
            _id: { $in: task.tarefasAnteriores },
            status: { $ne: 'done' },
          })
          .session(session)
          .exec();
        if (incompletas.length > 0) {
          Logger.warn(
            `Tarefa ${taskId} concluída com ${incompletas.length} tarefas anteriores pendentes`,
          );
        }
      }
      const user = await this.userService.findOne(userId);
      if (!user) throw new NotFoundException('Usuário não encontrado');
      const stats = {
        tarefasConcluidas: user.statistics?.tarefasConcluidas ?? 0,
        mediaNotas: user.statistics?.mediaNotas ?? 0,
        totalAvaliacoes: user.statistics?.totalAvaliacoes ?? 0,
        tarefasAvaliadas: user.statistics?.tarefasAvaliadas ?? 0,
        totalPontosRecebidos: user.statistics?.totalPontosRecebidos ?? 0,
        tempoMedioConclusao: user.statistics?.tempoMedioConclusao ?? 0,
        ultimaConclusao: user.statistics?.ultimaConclusao ?? null,
        ultimaAvaliacao: user.statistics?.ultimaAvaliacao ?? null,
      };
      const inicio = task.dataInicio || new Date();
      const duracao = (new Date().getTime() - inicio.getTime()) / 1000; // Segundos
      stats.tempoMedioConclusao =
        (stats.tempoMedioConclusao * stats.tarefasConcluidas + duracao) /
        (stats.tarefasConcluidas + 1);
      stats.tarefasConcluidas += 1;
      stats.ultimaConclusao = new Date();
      await this.userModel
        .findByIdAndUpdate(userId, { $set: { statistics: stats } }, { session })
        .exec();

      let avaliacaoTask = await this.avaliacaoTaskModel
        .findOne({ task_id: taskId, user_id_do_avaliado: userId })
        .session(session)
        .exec();

      if (!avaliacaoTask) {
        avaliacaoTask = new this.avaliacaoTaskModel({
          task_id: task._id,
          user_id_do_avaliado: new Types.ObjectId(userId),
          data_avaliacao: new Date(),
          gerada_automaticamente: true,
          code: code,
        });
        await avaliacaoTask.save({ session });
      } else {
        if (code && !avaliacaoTask.code) {
          avaliacaoTask.code = code;
          await avaliacaoTask.save({ session });
        }
      }

      const userTask = await this.taskUserModel
        .findOneAndUpdate(
          { task_id: taskId, user_id: userId },
          {
            tempo_gasto_horas,
            concluida_em: new Date(),
            avaliacao_id: avaliacaoTask._id,
          },
          { upsert: true, new: true, session },
        )
        .exec();

      const updatedTask = await this.taskModel
        .findByIdAndUpdate(
          taskId,
          { status: 'done', dataConclusao: new Date() },
          { new: true, session },
        )
        .populate('projeto criadaPor aprovadaPor atribuicoes')
        .exec();

      if (!updatedTask)
        throw new NotFoundException('Tarefa não encontrada após a conclusão.');

      const project = await this.projectModel
        .findById(task.projeto)
        .session(session)
        .exec();

      if (!project)
        throw new NotFoundException('Projeto da tarefa não encontrado.');

      await project.save({ session });

      // ** NOTIFICAÇÕES PARA completeTask (RF002 e RF015) **

      await this.notificationService.createNotification({
        recipient: task.criadaPor.toString(),
        message: `A tarefa "${task.titulo}" que você criou foi concluída pelo(a) ${user.nome || 'usuário(a) desconhecido(a)'}!`,
        eventType: NotificationEventType.TASK_COMPLETED,
        relatedToId: task._id.toString(),
        relatedToModel: 'Task',
      });

      // 2. Notificar o Scrum Master/PO do projeto (RF002)
      // Popular os usuários do projeto para ter acesso ao nome e papel
      const populatedProject = await this.projectModel
        .findById(project._id)
        .populate('users')
        .session(session)
        .exec();

      const projectScrumMastersAndPOs = populatedProject.users.filter(
        (u: any) => u.papel === 'Scrum Master' || u.papel === 'PO',
      );
      for (const sm of projectScrumMastersAndPOs) {
        if (
          sm.id.toString() !== task.criadaPor.toString() &&
          sm.id.toString() !== user._id.toString()
        ) {
          await this.notificationService.createNotification({
            recipient: sm.id.toString(),
            message: `A tarefa "${task.titulo}" do projeto "${populatedProject.nome}" foi concluída.`,
            eventType: NotificationEventType.TASK_COMPLETED,
            relatedToId: task._id.toString(),
            relatedToModel: 'Task',
          });
        }
      }

      // NOVO: 3. Notificar TODOS os membros do projeto (RF002)
      const notifiedRecipients = new Set([
        // Set para evitar notificações duplicadas
        task.criadaPor.toString(), // Criador já notificado
        user._id.toString(), // Executor já notificado
        ...projectScrumMastersAndPOs.map((sm: any) => sm.id.toString()), // SMs/POs já notificados
      ]);

      const allProjectMembers = populatedProject.users; // Obtém todos os membros do projeto
      for (const member of allProjectMembers) {
        if (!notifiedRecipients.has(member.id.toString())) {
          // Notifica apenas quem ainda não foi notificado
          await this.notificationService.createNotification({
            recipient: member.id.toString(),
            message: `A tarefa "${task.titulo}" do projeto "${populatedProject.nome}" foi concluída.`,
            eventType: NotificationEventType.TASK_COMPLETED,
            relatedToId: task._id.toString(),
            relatedToModel: 'Task',
          });
        }
      }

      // 4. RF015: Notificar usuários com tarefas dependentes
      const dependentTasks = await this.taskModel
        .find({
          tarefasAnteriores: task._id,
          status: { $nin: ['done', 'approved', 'cancelled'] },
        })
        .exec();

      for (const depTask of dependentTasks) {
        if (depTask.atribuicoes && depTask.atribuicoes.length > 0) {
          for (const assignedUserOfDepTask of depTask.atribuicoes) {
            if (assignedUserOfDepTask.toString() !== user._id.toString()) {
              await this.notificationService.createNotification({
                recipient: assignedUserOfDepTask.toString(),
                message: `A tarefa "${task.titulo}" (que sua tarefa "${depTask.titulo}" depende) foi concluída! Agora você pode avançar.`,
                eventType: NotificationEventType.TASK_COMPLETED,
                relatedToId: depTask._id.toString(),
                relatedToModel: 'Task',
              });
            }
          }
        }
      }

      await session.commitTransaction();
      return userTask;
    } catch (error) {
      await session.abortTransaction();
      this.logger.error(
        `Erro ao concluir tarefa ${taskId}: ${error.message}`,
        error.stack,
      );
      throw error;
    } finally {
      session.endSession();
    }
  }

  async findByUser(userId: string): Promise<Task[]> {
    const user = await this.userService.findOne(userId);
    if (!user) throw new NotFoundException('Usuário não encontrado');
    return this.taskModel
      .find({
        $or: [
          { criadaPor: userId },
          { aprovadaPor: userId },
          { atribuicoes: userId },
        ],
      })
      .populate(['projeto', 'criadaPor', 'aprovadaPor'])
      .exec();
  }

  async getBurndown(projectId: string, startDate: string) {
    const project = await this.projectModel.findById(projectId).exec();
    if (!project) throw new NotFoundException('Projeto não encontrado');
    const start = new Date(startDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const result = await this.taskModel
      .aggregate([
        {
          $match: {
            projeto: new Types.ObjectId(projectId),
            status: { $ne: 'done' },
          },
        },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
            pending: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ])
      .exec();
    const resultMap = new Map(result.map((r) => [r._id, r.pending]));
    const finalResult: Array<{ date: string; pending: number }> = [];
    for (let d = new Date(start); d <= today; d.setDate(d.getDate() + 1)) {
      const dateStr = d.toISOString().split('T')[0];
      finalResult.push({ date: dateStr, pending: resultMap.get(dateStr) || 0 });
    }
    return finalResult;
  }

  async getProjection(projectId: string, startDate: string) {
    const project = await this.projectModel.findById(projectId).exec();
    if (!project) throw new NotFoundException('Projeto não encontrado');
    const start = new Date(startDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const result = await this.taskModel
      .aggregate([
        {
          $match: {
            projeto: new Types.ObjectId(projectId),
            status: { $ne: 'done' },
            dataInicio: { $lte: today },
          },
        },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$dataInicio' } },
            pending: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ])
      .exec();
    const resultMap = new Map(result.map((r) => [r._id, r.pending]));
    const finalResult: Array<{ date: string; pending: number }> = [];
    for (let d = new Date(start); d <= today; d.setDate(d.getDate() + 1)) {
      const dateStr = d.toISOString().split('T')[0];
      finalResult.push({ date: dateStr, pending: resultMap.get(dateStr) || 0 });
    }
    return finalResult;
  }

  async recommendUsersForNewTask(
    projetoId: string,
    complexidade: Complexidade,
    tarefasAnteriores?: string[],
  ): Promise<Array<{ userId: string; nome: string; score: number }>> {
    const project = await this.projectModel.findById(projetoId).exec();
    if (!project) throw new NotFoundException('Projeto não encontrado');
    const recommendations = [];
    for (const user of project.users) {
      const userId = user.id;
      const userTasks = await this.taskModel
        .find({ projeto: projetoId, atribuicoes: userId })
        .exec();
      const completedSameComplexity = userTasks.filter(
        (t) => t.status === 'done' && t.complexidade === complexidade,
      ).length;
      const pendingTasks = userTasks.filter((t) => t.status !== 'done').length;
      const workedOnPreviousTasks =
        tarefasAnteriores?.some((prevId) =>
          userTasks.some((t) => t._id.toString() === prevId),
        ) ?? false;
      const userData = await this.userService.findOne(userId);
      const score =
        10 +
        (completedSameComplexity > 0 ? 15 : 0) +
        (pendingTasks < 3 ? 10 : 0) +
        (workedOnPreviousTasks ? 5 : 0) +
        (userData.statistics?.tarefasConcluidas || 0) * 0.5;
      recommendations.push({ userId, nome: user.nome, score });
    }
    return recommendations.sort((a, b) => b.score - a.score);
  }

  async reviewTaskUser(
    taskId: string,
    userId: string,
    comentario: string,
    nota: number,
    codigo?: string,
  ): Promise<TaskUser> {
    const session = await this.taskModel.startSession();
    session.startTransaction();
    try {
      const task = await this.taskModel
        .findById(taskId)
        .session(session)
        .exec();
      if (!task) throw new NotFoundException('Tarefa não encontrada');
      const user = await this.userService.findOne(userId);
      if (!user) throw new BadRequestException('Usuário não encontrado');
      const taskUser = await this.taskUserModel
        .findOne({ task_id: taskId, user_id: userId })
        .session(session)
        .exec();
      if (!taskUser || !taskUser.concluida_em) {
        throw new BadRequestException('Usuário não concluiu a tarefa');
      }
      if (taskUser.avaliacao_nota) {
        throw new BadRequestException('Tarefa já foi avaliada');
      }
      taskUser.avaliacao_comentario = comentario;
      taskUser.avaliacao_nota = nota;
      taskUser.avaliacao_codigo = codigo;
      await taskUser.save({ session });
      await this.userService.addScore(userId, nota);
      if (!task.avaliacaoId) {
        await this.taskModel
          .findByIdAndUpdate(taskId, { avaliacaoId: taskUser._id }, { session })
          .exec();
      }
      await session.commitTransaction();
      return taskUser;
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }

  async acknowledgeTask(taskId: string, userId: string): Promise<Task> {
    const session = await this.taskModel.startSession();
    session.startTransaction();
    try {
      const task = await this.taskModel
        .findById(taskId)
        .session(session)
        .exec();
      if (!task) {
        throw new NotFoundException('Tarefa não encontrada');
      }

      const isAssigned = task.atribuicoes.some(
        (assignedId) => assignedId.toString() === userId,
      );
      if (!isAssigned) {
        throw new ForbiddenException('Você não está atribuído a esta tarefa.');
      }

      if (task.recebidaPeloAtribuido) {
        throw new BadRequestException('Esta tarefa já foi confirmada.');
      }

      task.recebidaPeloAtribuido = true;
      const updatedTask = await task.save({ session });

      // No need to update project.tasks, as task details are managed in Task collection

      await session.commitTransaction();
      return updatedTask;
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }

  async findByAssignedAndUnacknowledged(userId: string): Promise<Task[]> {
    const user = await this.userService.findOne(userId);
    if (!user) throw new NotFoundException('Usuário não encontrado');

    return this.taskModel
      .find({
        atribuicoes: userId,
        recebidaPeloAtribuido: false,
        status: { $nin: ['done', 'approved', 'cancelled'] },
      })
      .populate(['projeto', 'criadaPor', 'aprovadaPor', 'atribuicoes'])
      .exec();
  }

  async findAssignedTasksForUser(userId: string): Promise<Task[]> {
    const user = await this.userService.findOne(userId);
    if (!user) throw new NotFoundException('Usuário não encontrado');

    return this.taskModel
      .find({
        atribuicoes: userId,
      })
      .populate('projeto criadaPor aprovadaPor atribuicoes')
      .exec();
  }

  // ====================================================================
  // MÉTODO DE AVALIAÇÃO (garantindo consistência)
  // ====================================================================
  async evaluate(
    evaluateTaskDto: EvaluateTaskDto,
    reviewerId: string,
  ): Promise<AvaliacaoTask> {
    const { taskId, nota, comentario } = evaluateTaskDto;
    const session = await this.taskModel.startSession();
    session.startTransaction();

    try {
      const task = await this.taskModel
        .findById(taskId)
        .session(session)
        .exec();
      if (!task) {
        throw new NotFoundException(`Tarefa com ID ${taskId} não encontrada.`);
      }
      if (task.avaliacaoId) {
        throw new BadRequestException('Esta tarefa já foi avaliada.');
      }
      if (!task.atribuicoes || task.atribuicoes.length === 0) {
        throw new NotFoundException(
          `Tarefa com ID ${taskId} não possui usuário para ser avaliado.`,
        );
      }
      const assignedUserId = task.atribuicoes[0];

      const newEvaluation = new this.avaliacaoTaskModel({
        task_id: task._id,
        user_id_do_avaliado: assignedUserId,
        user_id_do_avaliador: new Types.ObjectId(reviewerId),
        nota: nota,
        code: comentario,
        data_avaliacao: new Date(),
        gerada_automaticamente: false,
      });

      const savedEvaluation = await newEvaluation.save({ session });
      task.avaliacaoId = savedEvaluation._id as Types.ObjectId;
      await task.save({ session });

      await session.commitTransaction();
      return savedEvaluation;
    } catch (error) {
      await session.abortTransaction();
      this.logger.error(
        `Erro ao avaliar tarefa: ${error.message}`,
        error.stack,
      );
      throw error;
    } finally {
      session.endSession();
    }
  }

  // ====================================================================
  // MÉTODO DE BUSCAR TAREFAS CONCLUÍDAS (usando sua lógica funcional)
  // ====================================================================
  async getCompletedTasks(projectId: string): Promise<Task[]> {
    return this.taskModel
      .find({
        projeto: projectId,
        status: 'done',
      })
      .populate('projeto')
      .populate('criadaPor')
      .populate('aprovadaPor')
      .populate('atribuicoes')
      .populate('avaliacaoId')
      .exec();
  }

  /**
   * NOVO MÉTODO PARA BUSCAR TAREFAS CONCLUÍDAS
   */
  async findDoneTasks(projectId: string): Promise<Task[]> {
    return this.taskModel
      .find({ status: 'done', projeto: projectId })
      .populate('projeto')
      .populate('criadaPor')
      .populate('aprovadaPor')
      .populate('atribuicoes')
      .exec();
  }
}
