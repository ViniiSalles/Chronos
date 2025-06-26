// src/meetings/meeting.controller.ts
import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  Req,
  UseGuards,
  NotFoundException,
  BadRequestException, // Adicionar ForbiddenException para erros de permissão
} from '@nestjs/common';
import { MeetingService } from './meetings.service';
import { CreateMeetingDto } from './dto/create-meeting.dto';
import { UpdateMeetingDto } from './dto/update-meeting.dto';
import { FirebaseAuthGuard } from 'auth/firebase-auth.guard'; // Seu guard de autenticação Firebase

@Controller('meetings')
@UseGuards(FirebaseAuthGuard) // Proteger todas as rotas deste controller por padrão
export class MeetingController {
  constructor(private readonly meetingService: MeetingService) {}

  // POST /meetings
  @Post()
  async create(@Body() createMeetingDto: CreateMeetingDto, @Req() req: any) {
    const scrumMasterId = req.user?._id; // Obter o ID do SM do token
    if (!scrumMasterId) {
      throw new NotFoundException(
        'ID do Scrum Master autenticado não encontrado.',
      );
    }
    // O service validará se o usuário é realmente um SM do projeto
    return this.meetingService.create(
      createMeetingDto,
      scrumMasterId.toString(),
    );
  }

  // GET /meetings (pode ter query param projectId)
  @Get()
  async findAll(@Req() req: any, @Query('projectId') projectId?: string) {
    const userId = req.user?._id;
    if (!userId) {
      throw new NotFoundException('ID do usuário autenticado não encontrado.');
    }
    return this.meetingService.findAll(userId.toString(), projectId);
  }

  // GET /meetings/:id
  @Get(':id')
  async findOne(@Param('id') id: string, @Req() req: any) {
    const userId = req.user?._id;
    if (!userId) {
      throw new NotFoundException('ID do usuário autenticado não encontrado.');
    }
    // O service fará a verificação de acesso
    return this.meetingService.findOne(id, userId.toString());
  }

  // PATCH /meetings/:id
  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() updateMeetingDto: UpdateMeetingDto,
    @Req() req: any,
  ) {
    const modifierUserId = req.user?._id;
    if (!modifierUserId) {
      throw new NotFoundException('ID do usuário autenticado não encontrado.');
    }
    // O service fará a verificação de permissão (apenas SM criador)
    return this.meetingService.update(
      id,
      updateMeetingDto,
      modifierUserId.toString(),
    );
  }

  // DELETE /meetings/:id
  @Delete(':id')
  async remove(@Param('id') id: string, @Req() req: any) {
    const removerUserId = req.user?._id;
    if (!removerUserId) {
      throw new NotFoundException('ID do usuário autenticado não encontrado.');
    }
    // O service fará a verificação de permissão (apenas SM criador)
    await this.meetingService.remove(id, removerUserId.toString());
    return { message: 'Reunião removida com sucesso.' };
  }

  // PATCH /meetings/:id/participants (Adicionar participantes)
  @Patch(':id/add-participants')
  async addParticipants(
    @Param('id') meetingId: string,
    @Body('participantIds') participantIds: string[], // Espera um array de IDs
    @Req() req: any,
  ) {
    if (!Array.isArray(participantIds) || participantIds.length === 0) {
      throw new BadRequestException('Nenhum participante válido fornecido.');
    }
    const modifierUserId = req.user?._id;
    if (!modifierUserId) {
      throw new NotFoundException('ID do usuário autenticado não encontrado.');
    }
    return this.meetingService.addParticipants(
      meetingId,
      participantIds,
      modifierUserId.toString(),
    );
  }

  // PATCH /meetings/:id/remove-participants (Remover participantes)
  @Patch(':id/remove-participants')
  async removeParticipants(
    @Param('id') meetingId: string,
    @Body('participantIds') participantIds: string[], // Espera um array de IDs
    @Req() req: any,
  ) {
    if (!Array.isArray(participantIds) || participantIds.length === 0) {
      throw new BadRequestException('Nenhum participante válido fornecido.');
    }
    const modifierUserId = req.user?._id;
    if (!modifierUserId) {
      throw new NotFoundException('ID do usuário autenticado não encontrado.');
    }
    return this.meetingService.removeParticipants(
      meetingId,
      participantIds,
      modifierUserId.toString(),
    );
  }
}
