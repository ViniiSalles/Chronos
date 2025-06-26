import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { KanbanBoard, KanbanBoardSchema } from 'src/schema/kanban-board.schema';
import { Project, ProjectSchema } from 'src/schema/projeto.schema';
import { Task, TaskSchema } from 'src/schema/tarefa.schema';
import { User, UserSchema } from 'src/schema/usuario.schema';
import { KanbanController } from './kanban.controller';
import { KanbanService } from './kanban.service';
import { ProjectModule } from 'src/project/project.module';
import { TaskModule } from 'src/task/task.module';
import { UserModule } from 'src/user/user.module';
import { NotificationsModule } from 'src/notifications/notifications.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: KanbanBoard.name, schema: KanbanBoardSchema },
      // KanbanColumn não precisa ser registrado aqui se for usado apenas como subdocumento em KanbanBoardSchema.
      // Se fosse uma coleção separada, precisaria.
      { name: Project.name, schema: ProjectSchema },
      { name: Task.name, schema: TaskSchema },
      { name: User.name, schema: UserSchema },
    ]),
    // Importa módulos que contêm serviços injetados no KanbanService
    // Use forwardRef para resolver dependências circulares (se KanbanService injetar ProjectService ou TaskService, e vice-versa)
    forwardRef(() => ProjectModule), // Para ProjectService
    forwardRef(() => TaskModule), // Para TaskService
    forwardRef(() => UserModule), // Para UserService
    NotificationsModule, // Para NotificationService
  ],
  controllers: [KanbanController],
  providers: [KanbanService],
  exports: [KanbanService], // Exporte o serviço se outros módulos precisarem dele
})
export class KanbanModule {}
