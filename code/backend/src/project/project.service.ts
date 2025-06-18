import {
  forwardRef,
  Inject,
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Project, ProjectDocument } from 'src/schema/projeto.schema';
import { CreateProjectDto } from './dto/create-project.dto';
import { UpdateProjectDto } from './dto/update-project.dto';
import { User, UserDocument } from 'src/schema/usuario.schema';
import { Task, TaskDocument } from 'src/schema/tarefa.schema';
import { TaskUser, TaskUserDocument } from 'src/schema/tarefa-usuario.schema';
import { UserService } from 'src/user/user.service';
import { Complexidade } from 'src/types/types';

@Injectable()
export class ProjectService {
  constructor(
    @InjectModel(Project.name)
    private readonly projectModel: Model<ProjectDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    @InjectModel(Task.name) private readonly taskModel: Model<TaskDocument>,
    @InjectModel(TaskUser.name)
    private readonly taskUserModel: Model<TaskUserDocument>,
    @Inject(forwardRef(() => UserService)) private userService: UserService,
  ) { }

  async checkUserRole(
    projectId: string,
    userId: string,
  ): Promise<string | null> {
    const project = await this.projectModel.findById(projectId).exec();
    if (!project) {
      throw new NotFoundException('Projeto não encontrado');
    }
    const userInProject = project.users.find(
      (user) => user.id.toString() === userId,
    );
    return userInProject ? userInProject.papel : null;
  }

  async create(
    createProjectDto: CreateProjectDto,
    creatorUserId: string,
  ): Promise<Project> {
    const usersToAssign = [...(createProjectDto.users || [])];

    const creatorAlreadyAssigned = usersToAssign.some(
      (user) => user.id === creatorUserId,
    );

    if (!creatorAlreadyAssigned) {
      const creatorUser = await this.userModel.findById(creatorUserId).exec();
      if (!creatorUser) {
        throw new NotFoundException(`Usuário ${creatorUserId} não encontrado`);
      }
      usersToAssign.unshift({
        id: creatorUserId,
        nome: creatorUser.nome,
        email: creatorUser.email,
        papel: 'admin',
      });
    } else {
      const creatorEntry = usersToAssign.find(
        (user) => user.id === creatorUserId,
      );
      if (creatorEntry) {
        creatorEntry.papel = 'admin';
      }
    }

    for (const user of usersToAssign) {
      const exists = await this.userModel.findById(user.id).exec();
      if (!exists) {
        throw new NotFoundException(`Usuário ${user.id} não encontrado`);
      }
    }

    const session = await this.projectModel.startSession();
    session.startTransaction();
    try {
      const project = new this.projectModel({
        ...createProjectDto,
        users: usersToAssign,
        tasks: [], // Initialize tasks as an empty array of ObjectIds
      });
      const savedProject = await project.save({ session });
      await session.commitTransaction();
      return savedProject.populate('tasks'); // Populate tasks for the response
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }

  async findAll(): Promise<Project[]> {
    return this.projectModel.find().populate('tasks').exec();
  }

  async findAllByUserId(userId: string): Promise<Project[]> {
    const projects = await this.projectModel
      .find({ 'users.id': userId })
      .populate('tasks')
      .exec();
    if (!projects || projects.length === 0) {
      throw new NotFoundException(
        'Nenhum projeto encontrado para este usuário',
      );
    }
    return projects;
  }

  async findOne(id: string): Promise<Project> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException('ID de projeto inválido');
    }
    const project = await this.projectModel
      .findById(id)
      .populate('tasks')
      .exec();
    if (!project) throw new NotFoundException('Projeto não encontrado');
    return project;
  }

  async update(
    id: string,
    updateProjectDto: UpdateProjectDto,
  ): Promise<Project> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException('ID de projeto inválido');
    }
    if (updateProjectDto.users) {
      for (const user of updateProjectDto.users) {
        const exists = await this.userModel.findById(user.id).exec();
        if (!exists)
          throw new NotFoundException(`Usuário ${user.id} não encontrado`);
      }
    }
    const session = await this.projectModel.startSession();
    session.startTransaction();
    try {
      const updated = await this.projectModel
        .findByIdAndUpdate(id, updateProjectDto, { new: true, session })
        .populate('tasks')
        .exec();
      if (!updated) throw new NotFoundException('Projeto não encontrado');
      await session.commitTransaction();
      return updated;
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }

  async remove(id: string): Promise<Project> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException('ID de projeto inválido');
    }
    const session = await this.projectModel.startSession();
    session.startTransaction();
    try {
      const project = await this.projectModel
        .findById(id)
        .session(session)
        .exec();
      if (!project) throw new NotFoundException('Projeto não encontrado');
      await this.taskModel.deleteMany({ projeto: id }).session(session).exec();
      await this.taskUserModel
        .deleteMany({ projeto: id })
        .session(session)
        .exec();
      const deleted = await this.projectModel
        .findByIdAndDelete(id)
        .session(session)
        .populate('tasks')
        .exec();
      if (!deleted) throw new NotFoundException('Projeto não encontrado');
      await session.commitTransaction();
      return deleted;
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }

  async getMembers(
    projectId: string,
  ): Promise<{ id: string; nome: string; email: string; papel: string }[]> {
    if (!Types.ObjectId.isValid(projectId)) {
      throw new NotFoundException('ID de projeto inválido');
    }
    const project = await this.projectModel.findById(projectId).exec();
    if (!project) throw new NotFoundException('Projeto não encontrado');
    return project.users || [];
  }

  async removeMemberFromProject(
    projectId: string,
    userId: string,
  ): Promise<{ message: string }> {
    if (!Types.ObjectId.isValid(projectId)) {
      throw new NotFoundException('ID de projeto inválido');
    }
    const session = await this.projectModel.startSession();
    session.startTransaction();
    try {
      const project = await this.projectModel
        .findById(projectId)
        .session(session)
        .exec();
      if (!project) throw new NotFoundException('Projeto não encontrado');

      const updatedUsers = project.users.filter(
        (user) => user.id.toString() !== userId,
      );

      project.users = updatedUsers;
      await project.save({ session });
      await session.commitTransaction();
      return { message: 'Membro removido com sucesso' };
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }

  async getProjectReport(projectId: string): Promise<any> {
    if (!Types.ObjectId.isValid(projectId)) {
      throw new NotFoundException('ID de projeto inválido');
    }

    // Buscar o projeto e popular as tarefas e usuários para o relatório
    const project = await this.projectModel
      .findById(projectId)
      .populate({
        path: 'tasks', // Popula o array de ObjectIds de tasks
        model: this.taskModel, // Informa qual modelo referenciar
        populate: [
          // Popula campos dentro das tasks
          { path: 'atribuicoes', model: this.userModel, select: 'nome' }, // Popula atribuicoes para pegar o nome
          { path: 'projeto', model: this.projectModel, select: 'nome' }, // Opcional, se precisar do nome do projeto de dentro da task
        ],
      })
      .populate({
        path: 'users', // Popula o array de usuários (se users for ObjectId[])
        model: this.userModel,
        select: 'nome email papel', // Campos que você quer do user
      })
      .exec();

    if (!project) {
      throw new NotFoundException('Projeto não encontrado.');
    }

    // Certifique-se de que tasks é uma lista de documentos populados ou lide com o caso de ser ObjectId[]
    let tasks: TaskDocument[];
    if (
      project.tasks.length > 0 &&
      typeof project.tasks[0] === 'object' &&
      'titulo' in project.tasks[0]
    ) {
      // Já populado
      tasks = project.tasks as unknown as TaskDocument[];
    } else {
      // Não populado, buscar do banco
      tasks = await this.taskModel.find({ _id: { $in: project.tasks } }).exec();
    }

    // 1. Soma de tasks de cada membro (soma total mesmo)
    const tasksPerMember: {
      [memberId: string]: { nome: string; count: number };
    } = {};
    for (const member of project.users) {
      // project.users já deve estar populado ou ser o tipo correto
      tasksPerMember[member.id.toString()] = {
        nome: member.nome || 'Nome Desconhecido', // Acessar nome do membro
        count: 0,
      };
    }
    
    tasks.forEach((task) => {
      // console.log(task.atribuicoes);
      task.atribuicoes.forEach((assignedUser) => {
        
        const assignedUserId = assignedUser._id.toString();
        console.log(assignedUserId)
        console.log(tasksPerMember)
        if (tasksPerMember[assignedUserId]) {
          console.log("enyrou no if")
          tasksPerMember[assignedUserId].count = tasksPerMember[assignedUserId].count+1;
        }
      });
    });

    // console.log(tasksPerMember);


    // 2. Quantidade de task por nível de complexidade
    const tasksByComplexity: { [complexity: string]: number } = {};
    Object.values(Complexidade).forEach(
      (comp) => (tasksByComplexity[comp] = 0),
    ); // Inicializa com 0
    tasks.forEach((task) => {
      if (task.complexidade) {
        tasksByComplexity[task.complexidade]++;
      }
    });

    // 3. Quantidade de task por nível de prioridade
    const tasksByPriority: { [priority: string]: number } = {};
    // Assumindo que prioridade é String ('Alta', 'Média', 'Baixa')
    ['Alta', 'Média', 'Baixa'].forEach((p) => (tasksByPriority[p] = 0)); // Inicializa
    tasks.forEach((task) => {
      if (task.prioridade) {
        tasksByPriority[task.prioridade]++;
      }
    });

    // 4. Quantidade de tasks pendentes e concluídas
    let pendingTasks = 0;
    let completedTasks = 0;
    tasks.forEach((task) => {
      if (task.status === 'done' || task.status === 'approved') {
        // Assumindo 'done' ou 'approved' como concluídas
        completedTasks++;
      } else {
        pendingTasks++;
      }
    });

    // 5. Dados adicionais
    const numberOfMembers = project.users.length;
    const numberOfTasks = tasks.length;
    const daysRemaining = Math.max(
      0,
      Math.ceil(
        (project.data_fim.getTime() - new Date().getTime()) /
          (1000 * 60 * 60 * 24),
      ),
    ); // Dias restantes para finalização

    return {
      projectId: project._id.toString(),
      projectName: project.nome,
      numberOfMembers,
      numberOfTasks,
      daysRemaining,
      tasksPerMember: Object.values(tasksPerMember), // Converte para array
      tasksByComplexity,
      tasksByPriority,
      pendingTasks,
      completedTasks,
    };
  }
}
