import {
  forwardRef,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, ClientSession } from 'mongoose';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { User, UserDocument } from 'src/schema/usuario.schema';
import { Project } from 'src/schema/projeto.schema';
import { Task } from 'src/schema/tarefa.schema';
import { TaskUser } from 'src/schema/tarefa-usuario.schema';
import { TaskService } from 'src/task/task.service';

@Injectable()
export class UserService {
  constructor(
    @InjectModel(User.name) private userModel: Model<User>,
    @InjectModel(Project.name) private projectModel: Model<Project>,
    @InjectModel(Task.name) private taskModel: Model<Task>,
    @InjectModel(TaskUser.name) private taskUserModel: Model<TaskUser>,
    @Inject(forwardRef(() => TaskService)) private TaskService: TaskService, // Add UserService
  ) {}

  async create(createUserDto: CreateUserDto) {
    const session = await this.userModel.startSession();
    session.startTransaction();
    try {
      const user = new this.userModel(createUserDto);
      const savedUser = await user.save({ session });
      await session.commitTransaction();
      return savedUser;
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }

  async findAll() {
    return this.userModel.find().exec();
  }

  async findOne(id: string) {
    const user = await this.userModel.findById(id).exec();
    if (!user) throw new NotFoundException('Usuário não encontrado');
    return user;
  }

  async update(id: string, updateUserDto: UpdateUserDto) {
    const session = await this.userModel.startSession();
    session.startTransaction();
    try {
      const updatedUser = await this.userModel
        .findByIdAndUpdate(id, updateUserDto, { new: true, session })
        .exec();
      if (!updatedUser) throw new NotFoundException('Usuário não encontrado');
      // Atualizar o nome do usuário nos projetos onde ele aparece
      await this.projectModel.updateMany(
        { 'users.id': id },
        { $set: { 'users.$[elem].nome': updatedUser.nome } },
        { arrayFilters: [{ 'elem.id': id }] },
      );
      await session.commitTransaction();
      return updatedUser;
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }

  async updateByFirebaseUid(firebaseUid: string, updateUserDto: UpdateUserDto) {
    const updatedUser = await this.userModel.findOneAndUpdate(
      { firebaseUid: firebaseUid },
      updateUserDto,
      { new: true },
    );
    if (!updatedUser) throw new NotFoundException('Usuário não encontrado');

    // Atualizar o nome do usuário nos projetos onde ele aparece
    await this.projectModel.updateMany(
      { 'users.id': updatedUser.id },
      { $set: { 'users.$[elem].nome': updatedUser.nome } },
      { arrayFilters: [{ 'elem.id': updatedUser.id }] },
    );

    return updatedUser;
  }

  async remove(id: string) {
    const session = await this.userModel.startSession();
    session.startTransaction();
    try {
      const user = await this.userModel.findById(id).session(session).exec();
      if (!user) throw new NotFoundException('Usuário não encontrado');
      await this.projectModel
        .updateMany(
          { 'users.id': id },
          { $pull: { users: { id } } },
          { session },
        )
        .exec();
      await this.taskModel
        .updateMany(
          {
            $or: [{ criadaPor: id }, { aprovadaPor: id }, { atribuicoes: id }],
          },
          {
            $unset: { criadaPor: 1, aprovadaPor: 1 },
            $pull: { atribuicoes: id },
          },
          { session },
        )
        .exec();
      await this.taskUserModel
        .deleteMany({ user_id: id })
        .session(session)
        .exec();
      const deleted = await this.userModel
        .findByIdAndDelete(id)
        .session(session)
        .exec();
      await session.commitTransaction();
      return deleted;
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }

  async assignUserToProject(
    userId: string,
    projectId: string,
    papelNoProjeto: string,
  ) {
    const user = await this.userModel.findById(userId);
    if (!user) throw new NotFoundException('Usuário não encontrado');

    const project = await this.projectModel.findById(projectId);
    if (!project) throw new NotFoundException('Projeto não encontrado');

    const alreadyInProject = project.users?.some((u) => u.id === user.id);
    if (!alreadyInProject) {
      project.users = [
        ...(project.users || []),
        {
          id: user.id,
          nome: user.nome,
          email: user.email,
          papel: papelNoProjeto,
        },
      ];
      await project.save();
    } else {
      const userInProject = project.users.find((u) => u.id === user.id);
      if (userInProject && userInProject.papel !== papelNoProjeto) {
        userInProject.papel = papelNoProjeto;
        await project.save();
      }
    }
    await this.taskModel.updateMany(
      { criadaPor: user.id as any },
      { $set: { criada_por_nome: user.nome } },
    );

    await this.taskModel.updateMany(
      { aprovadaPor: user.id as any },
      { $set: { aprovada_por_nome: user.nome } },
    );

    return {
      message:
        'Usuário associado ao projeto com sucesso e registros atualizados',
    };
  }

  async addScore(
    userId: string,
    nota: number,
    session?: ClientSession,
  ): Promise<void> {
    const user = await this.userModel
      .findById(userId)
      .session(session || null)
      .exec();
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
    const novoTotal = stats.totalAvaliacoes + 1;
    const novaSoma = stats.totalPontosRecebidos + nota;
    stats.mediaNotas = novaSoma / novoTotal;
    stats.totalAvaliacoes = novoTotal;
    stats.totalPontosRecebidos = novaSoma;
    stats.ultimaAvaliacao = new Date();
    await this.userModel
      .findByIdAndUpdate(
        userId,
        {
          $inc: { score: nota },
          $set: { statistics: stats },
        },
        { session: session || null },
      )
      .exec();
  }

  async getMyProfile(userId: string): Promise<User> {
    const user = await this.userModel.findById(userId).exec();
    if (!user) {
      throw new NotFoundException('Perfil de usuário não encontrado.');
    }
    // Retorna o usuário com todas as suas informações, incluindo as estatísticas.
    return user;
  }

  async findByFirebaseUid(firebaseUid: string): Promise<UserDocument | null> {
    return this.userModel.findOne({ firebaseUid }).exec();
  }
}
