// src/meetings/meeting.service.ts
import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CreateMeetingDto } from './dto/create-meeting.dto';
import { UpdateMeetingDto } from './dto/update-meeting.dto';
import { Project, ProjectDocument } from 'src/schema/projeto.schema'; // Importe seu esquema de Projeto
import { User, UserDocument } from 'src/schema/usuario.schema'; // Importe seu esquema de Usuário
import { UserService } from 'src/user/user.service'; // Importe seu UserService
import { Meeting, MeetingDocument } from 'src/schema/reuniao.schema';

@Injectable()
export class MeetingService {
  private readonly logger = new Logger(MeetingService.name);

  constructor(
    @InjectModel(Meeting.name) private meetingModel: Model<MeetingDocument>,
    @InjectModel(Project.name) private projectModel: Model<ProjectDocument>, // Injete o modelo de Projeto
    @InjectModel(User.name) private userModel: Model<UserDocument>, // Injete o modelo de Usuário
    private userService: UserService, // Injete o UserService para buscar detalhes de usuários
  ) {}

  // ========================================================================
  // MÉTODOS AUXILIARES DE VALIDAÇÃO E PERMISSÃO
  // ========================================================================

  private async validateProjectAndScrumMaster(
    projectId: string,
    scrumMasterId: string,
    session: any, // Mongoose session
  ): Promise<ProjectDocument> {
    const project = await this.projectModel
      .findById(projectId)
      .session(session)
      .exec();
    if (!project) {
      throw new NotFoundException('Projeto não encontrado.');
    }

    const scrumMasterInProject = project.users.find(
      (u) => u.id.toString() === scrumMasterId,
    );

    return project;
  }

  private async validateParticipants(
    participantIds: string[],
    projectId: string,
    session: any, // Mongoose session
  ): Promise<void> {
    const project = await this.projectModel
      .findById(projectId)
      .session(session)
      .exec();
    if (!project) {
      throw new NotFoundException(
        'Projeto não encontrado (para validar participantes).',
      );
    }

    const projectUserIds = new Set(project.users.map((u) => u.id.toString()));

    for (const participantId of participantIds) {
      // Verifica se o participante existe
      const userExists = await this.userService.findOne(participantId);
      if (!userExists) {
        throw new NotFoundException(
          `Participante com ID ${participantId} não encontrado.`,
        );
      }
      // Verifica se o participante faz parte do projeto
      if (!projectUserIds.has(participantId)) {
        throw new BadRequestException(
          `Participante ${participantId} não faz parte do projeto.`,
        );
      }
    }
  }

  private async checkMeetingAccess(
    meetingId: string,
    userId: string,
  ): Promise<MeetingDocument> {
    const meeting = await this.meetingModel
      .findById(meetingId)
      .populate('project scrumMaster participants.user') // Popula dados relevantes
      .exec();
    if (!meeting) {
      throw new NotFoundException('Reunião não encontrada.');
    }

    const isScrumMaster = meeting.scrumMaster.toString() === userId;
    const isParticipant = meeting.participants.some(
      (p) => p.user.toString() === userId,
    );
    const isProjectMember = meeting.project // Assume que project é populado com users
      ? (meeting.project as unknown as ProjectDocument).users.some(
          (u) => u.id.toString() === userId,
        )
      : false;

    // Ajuste a lógica de permissão conforme necessário
    // Por exemplo, SM pode ver/editar tudo. Participantes só podem ver.
    if (!isScrumMaster && !isParticipant && !isProjectMember) {
      // Permissão para ver
      throw new ForbiddenException(
        'Você não tem permissão para acessar esta reunião.',
      );
    }

    return meeting;
  }

  // ========================================================================
  // MÉTODOS CRUD PRINCIPAIS
  // ========================================================================

  async create(
    createMeetingDto: CreateMeetingDto,
    scrumMasterId: string,
  ): Promise<Meeting> {
    const session = await this.meetingModel.startSession();
    session.startTransaction();
    try {
      // 1. Validar Projeto e Scrum Master
      await this.validateProjectAndScrumMaster(
        createMeetingDto.project,
        scrumMasterId,
        session,
      );

      // 2. Validar Participantes
      await this.validateParticipants(
        createMeetingDto.participants,
        createMeetingDto.project,
        session,
      );

      // 3. Criar a reunião
      const newMeeting = new this.meetingModel({
        ...createMeetingDto,
        scrumMaster: scrumMasterId, // Define o Scrum Master com o ID do usuário autenticado
        participants: createMeetingDto.participants.map((pId) => ({
          user: pId,
        })), // Mapeia IDs para o formato do subdocumento
      });

      const savedMeeting = await newMeeting.save({ session });
      await session.commitTransaction();
      return savedMeeting;
    } catch (error) {
      await session.abortTransaction();
      this.logger.error(`Erro ao criar reunião: ${error.message}`);
      throw error;
    } finally {
      session.endSession();
    }
  }

  async findAll(
    userId: string,
    projectId?: string,
  ): Promise<MeetingDocument[]> {
    const query: any = {};
    if (projectId) {
      query.project = projectId;
    }

    // Buscar reuniões onde o usuário é Scrum Master ou participante ou membro do projeto
    // Popula o projeto para verificar membros se necessário
    const meetings = await this.meetingModel
      .find({
        $or: [
          { scrumMaster: userId },
          { 'participants.user': userId },
          // Se quiser que todos os membros do projeto possam ver todas as reuniões
          // você precisaria de uma forma de filtrar isso via populate ou agregação.
          // Por simplicidade, por enquanto, apenas SM ou participante.
          // Para todos os membros do projeto verem:
          // $in: (await this.projectModel.find({ 'users.id': userId }).select('_id').exec()).map(p => p._id)
          // query.project = { $in: projectIds }
        ],
      })
      .populate('project scrumMaster participants.user')
      .exec();

    // Filtragem adicional se o critério for "membro do projeto" e não apenas SM/participante
    const accessibleMeetings = meetings.filter((meeting) => {
      const isScrumMaster = meeting.scrumMaster.toString() === userId;
      const isParticipant = meeting.participants.some(
        (p) => p.user.toString() === userId,
      );
      const isProjectMember = meeting.project
        ? (meeting.project as unknown as ProjectDocument).users.some(
            (u) => u.id.toString() === userId,
          )
        : false;

      // Se um projectId foi especificado, garanta que a reunião realmente pertence a ele
      if (projectId && meeting.project.toString() !== projectId) {
        return false;
      }

      return isScrumMaster || isParticipant || isProjectMember;
    });

    return accessibleMeetings;
  }

  async findOne(meetingId: string, userId: string): Promise<MeetingDocument> {
    // Reutiliza a lógica de acesso
    return this.checkMeetingAccess(meetingId, userId);
  }

  async update(
    meetingId: string,
    updateMeetingDto: UpdateMeetingDto,
    modifierUserId: string,
  ): Promise<Meeting> {
    const session = await this.meetingModel.startSession();
    session.startTransaction();
    try {
      const meeting = await this.checkMeetingAccess(meetingId, modifierUserId); // Verifica acesso e existência

      // Apenas o Scrum Master que criou a reunião pode atualizá-la
      if (meeting.scrumMaster.toString() !== modifierUserId) {
        throw new ForbiddenException(
          'Você não tem permissão para atualizar esta reunião. Apenas o Scrum Master criador pode.',
        );
      }

      // Validar Projeto (se o projeto for alterado)
      if (
        updateMeetingDto.project &&
        updateMeetingDto.project !== meeting.project.toString()
      ) {
        await this.validateProjectAndScrumMaster(
          // Validar SM no NOVO projeto
          updateMeetingDto.project,
          modifierUserId,
          session,
        );
      }

      // Validar Participantes (se a lista de participantes for atualizada)
      if (
        updateMeetingDto.participants &&
        updateMeetingDto.participants.length > 0
      ) {
        await this.validateParticipants(
          updateMeetingDto.participants,
          updateMeetingDto.project || meeting.project.toString(), // Usa o novo projeto ou o existente
          session,
        );
      }

      const updatedMeeting = await this.meetingModel
        .findByIdAndUpdate(meetingId, updateMeetingDto, { new: true, session })
        .populate('project scrumMaster participants.user')
        .exec();

      if (!updatedMeeting) {
        throw new NotFoundException('Reunião não encontrada após atualização.');
      }

      await session.commitTransaction();
      return updatedMeeting;
    } catch (error) {
      await session.abortTransaction();
      this.logger.error(
        `Erro ao atualizar reunião ${meetingId}: ${error.message}`,
      );
      throw error;
    } finally {
      session.endSession();
    }
  }

  async remove(meetingId: string, removerUserId: string): Promise<void> {
    const session = await this.meetingModel.startSession();
    session.startTransaction();
    try {
      const meeting = await this.checkMeetingAccess(meetingId, removerUserId); // Verifica acesso e existência

      // Apenas o Scrum Master que criou a reunião pode removê-la
      if (meeting.scrumMaster.toString() !== removerUserId) {
        throw new ForbiddenException(
          'Você não tem permissão para remover esta reunião. Apenas o Scrum Master criador pode.',
        );
      }

      const result = await this.meetingModel
        .findByIdAndDelete(meetingId)
        .session(session)
        .exec();

      if (!result) {
        throw new NotFoundException('Reunião não encontrada para remoção.');
      }

      await session.commitTransaction();
    } catch (error) {
      await session.abortTransaction();
      this.logger.error(
        `Erro ao remover reunião ${meetingId}: ${error.message}`,
      );
      throw error;
    } finally {
      session.endSession();
    }
  }

  // ========================================================================
  // MÉTODOS DE GERENCIAMENTO DE PARTICIPANTES (opcionais, mas úteis)
  // ========================================================================

  async addParticipants(
    meetingId: string,
    newParticipantIds: string[],
    modifierUserId: string,
  ): Promise<Meeting> {
    const session = await this.meetingModel.startSession();
    session.startTransaction();
    try {
      const meeting = await this.checkMeetingAccess(meetingId, modifierUserId);

      // Apenas o Scrum Master criador pode adicionar participantes
      if (meeting.scrumMaster.toString() !== modifierUserId) {
        throw new ForbiddenException(
          'Apenas o Scrum Master criador pode adicionar participantes.',
        );
      }

      // Validar os novos participantes
      await this.validateParticipants(
        newParticipantIds,
        meeting.project.toString(),
        session,
      );

      // Adicionar participantes que ainda não estão na lista
      const currentParticipantUsers = new Set(
        meeting.participants.map((p) => p.user.toString()),
      );
      const participantsToAdd = newParticipantIds.filter(
        (pId) => !currentParticipantUsers.has(pId),
      );

      if (participantsToAdd.length === 0) {
        throw new BadRequestException(
          'Nenhum novo participante válido para adicionar.',
        );
      }

      const updatedMeeting = await this.meetingModel
        .findByIdAndUpdate(
          meetingId,
          {
            $addToSet: {
              participants: {
                $each: participantsToAdd.map((pId) => ({ user: pId })),
              },
            },
          },
          { new: true, session },
        )
        .populate('project scrumMaster participants.user')
        .exec();

      if (!updatedMeeting) {
        throw new NotFoundException(
          'Reunião não encontrada durante adição de participantes.',
        );
      }

      await session.commitTransaction();
      return updatedMeeting;
    } catch (error) {
      await session.abortTransaction();
      this.logger.error(
        `Erro ao adicionar participantes à reunião ${meetingId}: ${error.message}`,
      );
      throw error;
    } finally {
      session.endSession();
    }
  }

  async removeParticipants(
    meetingId: string,
    participantIdsToRemove: string[],
    modifierUserId: string,
  ): Promise<Meeting> {
    const session = await this.meetingModel.startSession();
    session.startTransaction();
    try {
      const meeting = await this.checkMeetingAccess(meetingId, modifierUserId);

      // Apenas o Scrum Master criador pode remover participantes
      if (meeting.scrumMaster.toString() !== modifierUserId) {
        throw new ForbiddenException(
          'Apenas o Scrum Master criador pode remover participantes.',
        );
      }

      // Remover participantes
      const updatedMeeting = await this.meetingModel
        .findByIdAndUpdate(
          meetingId,
          {
            $pull: { participants: { user: { $in: participantIdsToRemove } } },
          },
          { new: true, session },
        )
        .populate('project scrumMaster participants.user')
        .exec();

      if (!updatedMeeting) {
        throw new NotFoundException(
          'Reunião não encontrada durante remoção de participantes.',
        );
      }

      await session.commitTransaction();
      return updatedMeeting;
    } catch (error) {
      await session.abortTransaction();
      this.logger.error(
        `Erro ao remover participantes da reunião ${meetingId}: ${error.message}`,
      );
      throw error;
    } finally {
      session.endSession();
    }
  }
}
