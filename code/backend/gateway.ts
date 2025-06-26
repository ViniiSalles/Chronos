// Em src/gateway/gateway.ts

import { OnModuleInit, Injectable } from '@nestjs/common'; // MODIFICADO: Adicionado Injectable
import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { UserService } from 'src/user/user.service'; // ADICIONADO: Importar o UserService

@Injectable() // ADICIONADO
@WebSocketGateway()
export class MyGateway
  implements OnModuleInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  // O mapa agora irá mapear o _id do MongoDB para o Socket
  private userSocketMap: Map<string, Socket> = new Map();

  // ADICIONADO: Injetar o UserService
  constructor(private readonly userService: UserService) {}

  onModuleInit() {
    this.server.on('connection', (socket: Socket) => {
      console.log(`Socket conectado: ${socket.id}`);
    });
  }

  // MODIFICADO: A função handleConnection agora é assíncrona
  async handleConnection(socket: Socket) {
    // Para clareza, o frontend deveria enviar 'firebaseUid' em vez de 'userId'
    const firebaseUid = socket.handshake.query.firebaseUid as string;

    if (!firebaseUid) {
      console.log(
        `Socket ${socket.id} desconectado: Nenhum firebaseUid fornecido`,
      );
      socket.disconnect();
      return;
    }

    // Busca o usuário no MongoDB usando o firebaseUid
    const user = await this.userService.findByFirebaseUid(firebaseUid);

    if (user && user._id) {
      const mongoUserId = user._id.toString();
      this.userSocketMap.set(mongoUserId, socket);
      // Armazena o mongoUserId no próprio socket para facilitar a desconexão
      socket.data.mongoUserId = mongoUserId;
      console.log(
        `Usuário ${mongoUserId} (Firebase: ${firebaseUid}) conectado com o socket ${socket.id}`,
      );
    } else {
      console.log(
        `Usuário com firebaseUid ${firebaseUid} não encontrado no banco. Desconectando socket ${socket.id}`,
      );
      socket.disconnect();
    }
  }

  // MODIFICADO: A lógica de desconexão agora usa o ID armazenado no socket
  handleDisconnect(socket: Socket) {
    const mongoUserId = socket.data.mongoUserId; // Pega o ID que armazenamos na conexão
    if (mongoUserId) {
      this.userSocketMap.delete(mongoUserId);
      console.log(`Usuário ${mongoUserId} desconectado.`);
    } else {
      console.log(
        `Socket ${socket.id} desconectado sem um mongoUserId associado.`,
      );
    }
  }

  // NENHUMA MUDANÇA NECESSÁRIA AQUI!
  // Esta função já recebe os _id's do MongoDB e o mapa agora está correto.
  emitToUsers(userIds: string[], event: string, data: any) {
    userIds.forEach((userId) => {
      const socket = this.userSocketMap.get(userId);
      if (socket) {
        socket.emit(event, data);
        console.log(`Emissão do evento ${event} para o usuário ${userId}`);
      } else {
        console.log(`Nenhum socket encontrado para o usuário ${userId}`);
      }
    });
  }

  // onNewMessage não precisa de alterações
}
