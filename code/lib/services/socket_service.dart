// lib/services/socket_service.dart

import 'dart:async';
import 'package:code/services/task_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  // Padrão Singleton para garantir uma única instância do serviço
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final _taskStreamController = StreamController<Task>.broadcast();

  // Stream para que a UI possa ouvir novas tarefas
  Stream<Task> get taskCreatedStream => _taskStreamController.stream;

  // Método para iniciar a conexão com o servidor WebSocket
  void connect() async {
    // Garante que o usuário esteja logado para obter o UID
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('SocketService: Usuário não logado. Não é possível conectar.');
      return;
    }
    final String userId = currentUser.uid;

    // Se já estiver conectado, não faz nada
    if (_socket != null && _socket!.connected) {
      print("SocketService: Já está conectado.");
      return;
    }

    // Desconecta qualquer conexão antiga antes de criar uma nova
    disconnect();

    print('SocketService: Conectando com o userId: $userId...');

    // Configuração da conexão.
    // O backend espera o 'userId' na query para mapear o socket.
    _socket = IO
        .io('https://chronos-production-f584.up.railway.app', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'query': {
        'userId': userId, // Essencial para o backend
      },
    });

    // Listeners para os eventos do Socket.IO
    _socket!.onConnect((_) {
      print(
          'SocketService: Conectado ao servidor WebSocket com socket id: ${_socket?.id}');
    });

    // *** OUVINTE PRINCIPAL PARA NOVAS TAREFAS ***
    _socket!.on('taskCreated', (data) {
      print('SocketService: Evento "taskCreated" recebido!');
      try {
        // O backend envia { msg: '...', content: Task }
        if (data is Map<String, dynamic> && data.containsKey('content')) {
          final taskData = data['content'] as Map<String, dynamic>;

          // O backend envia o campo 'titulo' da tarefa, mas o fromJson do frontend espera 'title'
          // É necessário adaptar os campos para o modelo do frontend.
          // O backend envia 'atribuicoes' como uma lista de IDs, o frontend em KanbanTaskItem espera 'assignedToUsers'
          // Como o evento é simples, vamos criar um objeto Task simples a partir dos dados recebidos.
          // Aqui, estamos assumindo que o `content` tem uma estrutura compatível com Task.fromJson
          final task = Task.fromJson(taskData);

          _taskStreamController.add(task);
        } else {
          print(
              'SocketService: Formato de dados inesperado para taskCreated: $data');
        }
      } catch (e) {
        print('SocketService: Erro ao processar o evento taskCreated: $e');
      }
    });

    _socket!.onDisconnect((_) => print('SocketService: Desconectado.'));
    _socket!
        .onError((error) => print('SocketService: Erro de conexão - $error'));
    _socket!.onConnectError(
        (error) => print('SocketService: Erro ao conectar - $error'));
  }

  // Método para desconectar do servidor
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    print('SocketService: Conexão encerrada.');
  }

  // Método para limpar os recursos ao fechar o app
  void dispose() {
    _taskStreamController.close();
    disconnect();
  }
}
