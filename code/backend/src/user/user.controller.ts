// user.controller.ts
import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Patch,
  Delete,
  UseGuards,
  Req,
  NotFoundException,
} from '@nestjs/common';
import { UserService } from './user.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { AssignUserToProjectDto } from './dto/assign-user-to-project.dto';
import { FirebaseAuthGuard } from 'auth/firebase-auth.guard';

@Controller('users')
export class UserController {
  constructor(private readonly userService: UserService) { }

  @Get('me')
  @UseGuards(FirebaseAuthGuard)
  async getMyProfile(@Req() req: any) {
    const userId = req.user?._id;
    if (!userId) {
      throw new NotFoundException('Usuário autenticado não encontrado.');
    }
    return this.userService.getMyProfile(userId.toString());
  }

  @Post()
  create(@Body() createUserDto: CreateUserDto) {
    return this.userService.create(createUserDto);
  }

  @Get()
  findAll() {
    return this.userService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.userService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateUserDto: UpdateUserDto) {
    return this.userService.update(id, updateUserDto);
  }

  @Patch('by-firebase/:firebaseUid')
  @UseGuards(FirebaseAuthGuard)
  updateByFirebaseUid(
    @Param('firebaseUid') firebaseUid: string,
    @Body() updateUserDto: UpdateUserDto,
  ) {
    return this.userService.updateByFirebaseUid(firebaseUid, updateUserDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.userService.remove(id);
  }

  @Post(':userId/assign-to-project/:projectId')
  assignToProject(
    @Param('userId') userId: string,
    @Param('projectId') projectId: string,
    @Body() assignUserToProjectDto: AssignUserToProjectDto,
  ) {
    return this.userService.assignUserToProject(userId, projectId, assignUserToProjectDto.papel);
  }

}
