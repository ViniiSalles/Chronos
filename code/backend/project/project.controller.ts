import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  Req,
  NotFoundException,
} from '@nestjs/common';
import { ProjectService } from './project.service';
import { CreateProjectDto } from './dto/create-project.dto';
import { UpdateProjectDto } from './dto/update-project.dto';
import { FirebaseAuthGuard } from '../../auth/firebase-auth.guard';

@Controller('project')
export class ProjectController {
  constructor(private readonly projectService: ProjectService) { }

  @Post()
  // Certifique-se de que o seu AuthGuard está aplicado aqui para que `req.user` exista
  @UseGuards(FirebaseAuthGuard) // Exemplo com JWT AuthGuard. Use o seu guard de Firebase.
  async create(@Body() createProjectDto: CreateProjectDto, @Req() req: any) {
    // Injete o objeto Request
    // req.user conterá os dados do usuário autenticado após o guard
    const userId = req.user?._id; // ou req.user?.uid, dependendo de como seu guard mapeia

    if (!userId) {
      throw new NotFoundException(
        'ID do usuário autenticado não encontrado na requisição.',
      );
    }

    return this.projectService.create(createProjectDto, userId.toString()); // Passe o userId para o serviço
  }

  @Get()
  findAll() {
    return this.projectService.findAll();
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('my-projects')
  async findMyProjects(@Req() request: any) {
    const userId = request.user?._id; // Acessa o _id do usuário anexado pelo FirebaseAuthGuard

    if (!userId) {
      // Este caso não deve ocorrer se o FirebaseAuthGuard funcionar corretamente e sempre anexar um usuário válido.
      throw new NotFoundException(
        'ID do usuário autenticado não encontrado na requisição.',
      );
    }
    // O método findAllByUserId já deve existir no seu ProjectService
    return this.projectService.findAllByUserId(userId.toString()); // Converte para string se necessário
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.projectService.findOne(id);
  }

  @UseGuards(FirebaseAuthGuard)
  @Patch(':id')
  update(@Param('id') id: string, @Body() updateProjectDto: UpdateProjectDto) {
    return this.projectService.update(id, updateProjectDto);
  }

  @UseGuards(FirebaseAuthGuard)
  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.projectService.remove(id);
  }

  @Get(':projectId/members')
  getProjectMembers(@Param('projectId') projectId: string) {
    return this.projectService.getMembers(projectId);
  }

  @Delete(':projectId/remove-member/:userId')
  removeUser(
    @Param('projectId') projectId: string,
    @Param('userId') userId: string,
  ) {
    return this.projectService.removeMemberFromProject(projectId, userId);
  }

  @Get(':projectId/report')
  async getProjectReport(@Param('projectId') projectId: string) {
    return this.projectService.getProjectReport(projectId);
  }

  @Get(':projectId/my-role')
  @UseGuards(FirebaseAuthGuard) // Protege o endpoint e busca o usuário
  async getMyRoleInProject(@Param('projectId') projectId: string, @Req() req: any) {
    // O FirebaseAuthGuard anexa o usuário do MongoDB ao objeto `req`.
    const userId = req.user?._id;

    if (!userId) {
      throw new NotFoundException('Usuário autenticado não encontrado.');
    }

    // Chama o serviço com o ID correto do MongoDB.
    const role = await this.projectService.checkUserRole(projectId, userId.toString());

    // Retorna a resposta em um formato JSON consistente.
    return { role: role };
  }
}
