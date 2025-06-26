import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  BadRequestException,
  NotFoundException,
  Req,
  UseGuards,
} from '@nestjs/common';
import { TaskService } from './task.service';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskDto } from './dto/update-task.dto';
import { Complexidade } from 'src/types/types';
import { FirebaseAuthGuard } from 'auth/firebase-auth.guard';
import { CompleteTaskDto } from './dto/complete-task.dto';
import { EvaluateTaskDto } from './dto/evaluate-task.dto';

@Controller('tasks')
export class TaskController {
  constructor(private readonly taskService: TaskService) { }

  @Get('my-unacknowledged') // NOVO ENDPOINT
  @UseGuards(FirebaseAuthGuard) // Protege o endpoint com o guard de autenticação
  async getMyUnacknowledgedTasks(@Req() req: any) {
    const userId = req.user?._id; // Obtém o ID do usuário autenticado
    if (!userId) {
      throw new NotFoundException(
        'ID do usuário autenticado não encontrado na requisição.',
      );
    }
    return this.taskService.findByAssignedAndUnacknowledged(userId.toString());
  }

  @Get('my-assigned') // Endpoint mais genérico para tarefas atribuídas
  @UseGuards(FirebaseAuthGuard)
  async getMyAssignedTasks(@Req() req: any) {
    const userId = req.user?._id;
    if (!userId) {
      throw new NotFoundException(
        'ID do usuário autenticado não encontrado na requisição.',
      );
    }
    return this.taskService.findAssignedTasksForUser(userId.toString());
  }

  @Post()
  @UseGuards(FirebaseAuthGuard) // Garante que `req.user` esteja disponível
  async create(@Body() createTaskDto: CreateTaskDto, @Req() req: any) {
    const userId = req.user?._id; // ou req.user?.uid, dependendo de como seu guard mapeia
    if (!userId) {
      throw new NotFoundException(
        'ID do usuário autenticado não encontrado na requisição.',
      );
    }
    // Passa o DTO e o userId para o serviço
    return this.taskService.create(createTaskDto, userId.toString());
  }

  @Get()
  findAll() {
    return this.taskService.findAll();
  }

  @Get('recommendations')
  async getUserRecommendations(
    @Query('projeto') projetoId: string,
    @Query('complexidade') complexidade: Complexidade,
    @Query('tarefasAnteriores') tarefasAnteriores?: string | string[],
  ) {
    if (!projetoId || !complexidade) {
      throw new BadRequestException('projeto e complexidade são obrigatórios');
    }

    const tarefasArray = Array.isArray(tarefasAnteriores)
      ? tarefasAnteriores
      : tarefasAnteriores
        ? [tarefasAnteriores]
        : [];

    return this.taskService.recommendUsersForNewTask(
      projetoId,
      complexidade,
      tarefasArray,
    );
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.taskService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateTaskDto: UpdateTaskDto) {
    return this.taskService.update(id, updateTaskDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.taskService.remove(id);
  }

  @Get('user/:userId')
  async getTasksByUser(@Param('userId') userId: string) {
    return this.taskService.findByUser(userId);
  }

  @Patch(':id/complete')
  @UseGuards(FirebaseAuthGuard) // Adicionar o guard de autenticação aqui
  async completeTask(
    @Param('id') taskId: string,
    @Body() body: Omit<CompleteTaskDto, 'userId'>, // ALTERADO: userId não vem mais do body
    @Req() req: any, // Adicionar @Req() para acessar o usuário autenticado
  ) {
    const userId = req.user?._id; // Pegar o userId do objeto de requisição
    if (!userId) {
      throw new NotFoundException(
        'ID do usuário autenticado não encontrado na requisição.',
      );
    }

    return this.taskService.completeTask(
      taskId,
      userId.toString(), // Passar o userId obtido do token
      body.tempo_gasto_horas,
      body.code,
    );
  }

  @Get('burndown/:projectId')
  async burndown(
    @Param('projectId') projectId: string,
    @Query('start') start: string,
  ) {
    return this.taskService.getBurndown(projectId, start);
  }

  @Get('projection/:projectId')
  async projection(
    @Param('projectId') projectId: string,
    @Query('start') start: string,
  ) {
    return this.taskService.getProjection(projectId, start);
  }

  @Patch(':id/review/:userId')
  async reviewTaskUser(
    @Param('id') taskId: string,
    @Param('userId') userId: string,
    @Body() body: { comentario: string; nota: number; codigo?: string },
  ) {
    return this.taskService.reviewTaskUser(
      taskId,
      userId,
      body.comentario,
      body.nota,
      body.codigo,
    );
  }

  @Patch(':id/acknowledge') // NOVO ENDPOINT
  @UseGuards(FirebaseAuthGuard) // Garante que o usuário esteja autenticado
  async acknowledgeTask(@Param('id') taskId: string, @Req() req: any) {
    const userId = req.user?._id; // ID do usuário autenticado (que está tentando confirmar)
    if (!userId) {
      throw new NotFoundException('ID do usuário autenticado não encontrado.');
    }
    // A chamada ao service incluirá o ID da tarefa e o ID do usuário que está confirmando
    return this.taskService.acknowledgeTask(taskId, userId.toString());
  }

  @Post('evaluate')
  @UseGuards(FirebaseAuthGuard)
  async evaluate(@Body() evaluateTaskDto: EvaluateTaskDto, @Req() req) {
    const reviewerId = req.user.uid; // ID do gerente que está avaliando
    return this.taskService.evaluate(evaluateTaskDto, reviewerId);
  }

  @Get('completed/:projectId')
  @UseGuards(FirebaseAuthGuard)
  async getCompletedTasks(@Param('projectId') projectId: string) {
    return this.taskService.getCompletedTasks(projectId);
  }

  @Get('status/:projectId')
  @UseGuards(FirebaseAuthGuard)
  async findDoneTasks(@Param('projectId') projectId: string) {
    return this.taskService.findDoneTasks(projectId);
  }
}
