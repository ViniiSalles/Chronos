import { Injectable } from '@nestjs/common';
import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { UserService } from 'src/user/user.service';

// --- ATUALIZAÇÃO PRINCIPAL ---
// Adicionada a configuração de CORS diretamente no decorator.
// Isto é essencial para permitir que o seu frontend (em outro domínio) se conecte.
@WebSocketGateway({
  cors: {
    origin: '*', // Em produção, mude para o URL do seu frontend para mais segurança.
    methods: ['GET', 'POST'],
    credentials: true,
  },
})
@Injectable()
export class MyGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private userSocketMap: Map<string, Socket> = new Map();

  constructor(private readonly userService: UserService) { }

  // A função onModuleInit foi removida por ser redundante.
  // O NestJS já usa handleConnection para gerir novas conexões.

  async handleConnection(socket: Socket) {
    const firebaseUid = socket.handshake.query.firebaseUid as string;

    if (!firebaseUid) {
      console.log(`Socket ${socket.id} desconectado: Nenhum firebaseUid fornecido.`);
      socket.disconnect();
      return;
    }

    try {
      const user = await this.userService.findByFirebaseUid(firebaseUid);

      if (user && user._id) {
        const mongoUserId = user._id.toString();
        this.userSocketMap.set(mongoUserId, socket);
        // Armazena o mongoUserId no socket para uso na desconexão
        socket.data.mongoUserId = mongoUserId;
        console.log(`Usuário ${mongoUserId} (Firebase: ${firebaseUid}) conectado com o socket ${socket.id}`);
      } else {
        console.log(`Usuário com firebaseUid ${firebaseUid} não encontrado. Desconectando socket ${socket.id}`);
        socket.disconnect();
      }
    } catch (error) {
      console.error(`Erro ao processar conexão para o firebaseUid ${firebaseUid}:`, error);
      socket.disconnect();
    }
  }

  handleDisconnect(socket: Socket) {
    const mongoUserId = socket.data.mongoUserId;
    if (mongoUserId) {
      this.userSocketMap.delete(mongoUserId);
      console.log(`Usuário ${mongoUserId} desconectado (Socket: ${socket.id}).`);
    } else {
      // Este log é normal para sockets que não completaram a autenticação
      // console.log(`Socket ${socket.id} desconectado sem um mongoUserId associado.`);
    }
  }

  emitToUsers(userIds: string[], event: string, data: any) {
    console.log(`Tentando emitir evento '${event}' para os usuários:`, userIds);
    userIds.forEach((userId) => {
      const socket = this.userSocketMap.get(userId);
      if (socket) {
        socket.emit(event, data);
        console.log(`--> Evento '${event}' emitido com sucesso para o usuário ${userId}`);
      } else {
        console.log(`--> Nenhum socket online encontrado para o usuário ${userId}`);
      }
    });
  }
}