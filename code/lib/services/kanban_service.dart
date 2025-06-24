import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

// === Modelos Frontend para o Kanban ===
// Estes modelos refletem a estrutura de dados que o backend envia para o Kanban.

// Modelo para uma coluna Kanban
class KanbanColumn {
  final String id;
  final String name;
  final int order;
  final String statusMapping;
  final List<KanbanTaskItem>
      tasks; // Tarefas dentro desta coluna (serão populadas)

  KanbanColumn({
    required this.id,
    required this.name,
    required this.order,
    required this.statusMapping,
    this.tasks = const [],
  });

  factory KanbanColumn.fromJson(Map<String, dynamic> json) {
    return KanbanColumn(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      statusMapping: json['statusMapping']?.toString() ?? '',
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((t) => KanbanTaskItem.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// Modelo para um item de tarefa dentro de uma coluna Kanban
// Contém os dados essenciais para exibir no card do Kanban
class KanbanTaskItem {
  final String id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String complexidade;
  final DateTime? deadline;
  final String kanbanColumnId;
  final int orderInColumn;
  final List<KanbanUserItem> assignedToUsers; // Usuários atribuídos (populados)
  final KanbanUserItem? createdByUser; // Usuário criador (populado)
  final KanbanUserItem? approvedByUser; // Usuário aprovador (populado)
  final bool? recebidaPeloAtribuido;

  KanbanTaskItem({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.complexidade,
    this.deadline,
    required this.kanbanColumnId,
    required this.orderInColumn,
    this.assignedToUsers = const [],
    this.createdByUser,
    this.approvedByUser,
    this.recebidaPeloAtribuido,
  });

  factory KanbanTaskItem.fromJson(Map<String, dynamic> json) {
    return KanbanTaskItem(
      id: json['id']?.toString() ?? '',
      title: json['titulo']?.toString() ?? '',
      description: json['descricao']?.toString(),
      status: json['status']?.toString() ?? '',
      priority: json['prioridade']?.toString() ?? '',
      complexidade: json['complexidade']?.toString() ?? '',
      deadline: json['dataLimite'] != null
          ? DateTime.parse(json['dataLimite'].toString())
          : null,
      kanbanColumnId: json['kanbanColumnId']?.toString() ?? '',
      orderInColumn: (json['orderInColumn'] as num?)?.toInt() ?? 0,
      assignedToUsers: (json['assignedToUsers'] as List<dynamic>?)
              ?.map((u) => KanbanUserItem.fromJson(u as Map<String, dynamic>))
              .toList() ??
          [],
      createdByUser: json['createdByUser'] is Map<String, dynamic>
          ? KanbanUserItem.fromJson(
              json['createdByUser'] as Map<String, dynamic>)
          : null,
      approvedByUser: json['aprovadoByUser'] is Map<String, dynamic>
          ? KanbanUserItem.fromJson(
              json['aprovadoByUser'] as Map<String, dynamic>)
          : null,
      recebidaPeloAtribuido: json['recebidaPeloAtribuido'] as bool?,
    );
  }
}

// Modelo para dados de usuário simplificados (nome e id) para Kanban
class KanbanUserItem {
  final String id;
  final String nome;

  KanbanUserItem({required this.id, required this.nome});

  factory KanbanUserItem.fromJson(Map<String, dynamic> json) {
    return KanbanUserItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? 'Nome Desconhecido',
    );
  }
}

// Modelo para o Quadro Kanban completo
class KanbanBoard {
  final String id;
  final String projectId;
  final String projectName;
  final List<KanbanColumn> columns;

  KanbanBoard({
    required this.id,
    required this.projectId,
    required this.projectName,
    this.columns = const [],
  });

  factory KanbanBoard.fromJson(Map<String, dynamic> json) {
    return KanbanBoard(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      projectName:
          json['projectName']?.toString() ?? 'Nome do Projeto Indisponível',
      columns: (json['columns'] as List<dynamic>?)
              ?.map((c) => KanbanColumn.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// === Serviço Kanban ===
class KanbanService {
  static const String _kanbanEndpoint = '/kanban';
  static const String _baseUrl =
      'https://chronos-production-f584.up.railway.app'; // Sua URL base do backend

  static Future<String?> _getToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await user.getIdToken();
      return token;
    }
    print('KanbanService: Usuário não autenticado.');
    return null;
  }

  /// Busca o quadro Kanban completo de um projeto, incluindo suas colunas e tarefas.
  /// @param projectId O ID do projeto.
  /// @returns Um objeto KanbanBoard.
  static Future<KanbanBoard?> getKanbanBoard(String projectId) async {
    final String? token = await _getToken();
    if (token == null) {
      print(
          'KanbanService (getKanbanBoard): Token de autenticação não encontrado.');
      return null;
    }

    final Uri url = Uri.parse('$_baseUrl$_kanbanEndpoint/$projectId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            json.decode(utf8.decode(response.bodyBytes));
        return KanbanBoard.fromJson(responseData);
      } else if (response.statusCode == 404) {
        print(
            'KanbanService (getKanbanBoard): Quadro Kanban não encontrado para o projeto $projectId.');
        return null; // Retorna null se não encontrar o board
      } else {
        print(
            'KanbanService (getKanbanBoard): Erro ao buscar quadro Kanban. Status: ${response.statusCode}, Corpo: ${response.body}');
        throw Exception(
            'Falha ao carregar quadro Kanban: ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print(
          'KanbanService (getKanbanBoard): Exceção ao buscar quadro Kanban: $e');
      throw Exception('Exceção ao buscar quadro Kanban: ${e.toString()}');
    }
  }

  /// Cria um novo quadro Kanban para um projeto.
  /// @param projectId O ID do projeto.
  /// @returns O quadro Kanban criado.
  static Future<KanbanBoard?> createKanbanBoard(String projectId) async {
    final String? token = await _getToken();
    if (token == null) {
      print(
          'KanbanService (createKanbanBoard): Token de autenticação não encontrado.');
      return null;
    }

    final Uri url = Uri.parse('$_baseUrl$_kanbanEndpoint');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({'projectId': projectId}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            json.decode(utf8.decode(response.bodyBytes));
        return KanbanBoard.fromJson(responseData);
      } else {
        print(
            'KanbanService (createKanbanBoard): Erro ao criar quadro Kanban. Status: ${response.statusCode}, Corpo: ${response.body}');
        throw Exception(
            'Falha ao criar quadro Kanban: ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print(
          'KanbanService (createKanbanBoard): Exceção ao criar quadro Kanban: $e');
      throw Exception('Exceção ao criar quadro Kanban: ${e.toString()}');
    }
  }

  /// Move uma tarefa para uma nova coluna Kanban e atualiza sua ordem.
  /// @param taskId O ID da tarefa a ser movida.
  /// @param newColumnId O ID da nova coluna.
  /// @param newOrder A nova ordem da tarefa na coluna.
  /// @returns true se a operação for bem-sucedida.
  static Future<bool> moveKanbanTask(
      String taskId, String newColumnId, int newOrder) async {
    final String? token = await _getToken();
    if (token == null) {
      print(
          'KanbanService (moveKanbanTask): Token de autenticação não encontrado.');
      return false;
    }

    final Uri url = Uri.parse('$_baseUrl$_kanbanEndpoint/tasks/$taskId/move');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'newColumnId': newColumnId,
          'newOrder': newOrder,
        }),
      );

      if (response.statusCode == 200) {
        print('Tarefa $taskId movida para coluna $newColumnId com sucesso!');
        return true;
      } else {
        print(
            'KanbanService (moveKanbanTask): Erro ao mover tarefa. Status: ${response.statusCode}, Corpo: ${response.body}');
        throw Exception(
            'Falha ao mover tarefa Kanban: ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print('KanbanService (moveKanbanTask): Exceção ao mover tarefa: $e');
      throw Exception('Exceção ao mover tarefa Kanban: ${e.toString()}');
    }
  }

  // --- Métodos para gerenciamento de Colunas (Opcional, pode ser adicionado depois) ---

  /// Adiciona uma nova coluna ao quadro Kanban.
  /// @param boardId ID do quadro Kanban.
  /// @param columnId ID da nova coluna.
  /// @param name Nome da coluna.
  /// @param order Ordem da coluna.
  /// @param statusMapping Mapeamento de status.
  static Future<bool> createKanbanColumn(String boardId, String columnId,
      String name, int order, String statusMapping) async {
    final String? token = await _getToken();
    if (token == null) return false;

    final Uri url = Uri.parse('$_baseUrl$_kanbanEndpoint/$boardId/columns');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'id': columnId,
          'name': name,
          'order': order,
          'statusMapping': statusMapping,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Coluna $name criada com sucesso!');
        return true;
      } else {
        print('Erro ao criar coluna: ${response.body}');
        throw Exception(
            'Falha ao criar coluna Kanban: ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print('Exceção ao criar coluna: $e');
      throw Exception('Exceção ao criar coluna Kanban: ${e.toString()}');
    }
  }

  /// Atualiza uma coluna existente no quadro Kanban.
  /// @param boardId ID do quadro Kanban.
  /// @param columnId ID da coluna a ser atualizada.
  /// @param name Novo nome (opcional).
  /// @param order Nova ordem (opcional).
  /// @param statusMapping Novo statusMapping (opcional).
  static Future<bool> updateKanbanColumn(String boardId, String columnId,
      {String? name, int? order, String? statusMapping}) async {
    final String? token = await _getToken();
    if (token == null) return false;

    final Uri url =
        Uri.parse('$_baseUrl$_kanbanEndpoint/$boardId/columns/$columnId');
    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name;
    if (order != null) body['order'] = order;
    if (statusMapping != null) body['statusMapping'] = statusMapping;

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        print('Coluna $columnId atualizada com sucesso!');
        return true;
      } else {
        print('Erro ao atualizar coluna: ${response.body}');
        throw Exception(
            'Falha ao atualizar coluna Kanban: ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print('Exceção ao atualizar coluna: $e');
      throw Exception('Exceção ao atualizar coluna Kanban: ${e.toString()}');
    }
  }

  /// Remove uma coluna do quadro Kanban.
  /// @param boardId ID do quadro Kanban.
  /// @param columnId ID da coluna a ser removida.
  static Future<bool> deleteKanbanColumn(
      String boardId, String columnId) async {
    final String? token = await _getToken();
    if (token == null) return false;

    final Uri url =
        Uri.parse('$_baseUrl$_kanbanEndpoint/$boardId/columns/$columnId');
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('Coluna $columnId removida com sucesso!');
        return true;
      } else {
        print('Erro ao deletar coluna: ${response.body}');
        throw Exception(
            'Falha ao deletar coluna Kanban: ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print('Exceção ao deletar coluna: $e');
      throw Exception('Exceção ao deletar coluna Kanban: ${e.toString()}');
    }
  }
}
