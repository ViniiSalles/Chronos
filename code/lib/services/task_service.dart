import 'dart:convert'; // Para jsonDecode e utf8
import 'package:http/http.dart' as http; // Para chamadas HTTP
import 'package:firebase_auth/firebase_auth.dart'; // Para autenticação Firebase

// Certifique-se de que este import esteja correto
// import 'package:code/servicesMobile/api_service.dart'; // Comentado, pois não é usado diretamente aqui

// Definição do Enum TaskStatus
enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled,
  // Se você tiver um status 'approved' no backend, adicione aqui
  // approved,
}

// Classe auxiliar para dados de Usuário (usada para 'criadaPor' e 'aprovadaPor' populados)
class UserData {
  final String id;
  final String nome;
  final String? email;

  UserData({
    required this.id,
    required this.nome,
    this.email,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['_id']?.toString() ??
          json['id']?.toString() ??
          '', // Pega _id ou id
      nome: json['nome']?.toString() ?? 'Nome Indisponível',
      email: json['email']?.toString(),
    );
  }
}

// Classe para o objeto Projeto aninhado na Task, conforme retornado pelo backend
class Projeto {
  final String id;
  final String nome;
  final String? descricao;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final String? status;
  final List<String> tasks; // IDs de tarefa
  final List<Map<String, dynamic>>
      users; // Continua Map<String, dynamic> para users

  Projeto({
    required this.id,
    required this.nome,
    this.descricao,
    this.dataInicio,
    this.dataFim,
    this.status,
    this.tasks = const [], // Inicializa como lista de strings vazia
    this.users = const [],
  });

  factory Projeto.fromJson(Map<String, dynamic> json) {
    return Projeto(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString(),
      dataInicio: json['dataInicio'] != null
          ? DateTime.parse(json['dataInicio'].toString())
          : null,
      dataFim: json['data_fim'] != null
          ? DateTime.parse(json['data_fim'].toString())
          : null,
      status: json['status']?.toString(),
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          [], // Converte IDs para String
      users: (json['users'] as List<dynamic>?)
              ?.map((u) => u as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}

// Definição da Classe Task
class Task {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final DateTime? deadline;
  final TaskStatus status;
  final int priority;
  final String? complexidade;
  final String? assignedTo;
  final String? projectId;
  final Projeto? projeto;
  final UserData? criadaPorUser;
  final UserData? aprovadaPorUser;
  final List<String>? tarefasAnteriores;
  final bool? recebidaPeloAtribuido;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    this.deadline,
    required this.status,
    required this.priority,
    this.complexidade,
    this.assignedTo,
    this.projectId,
    this.projeto,
    this.criadaPorUser,
    this.aprovadaPorUser,
    this.tarefasAnteriores,
    this.recebidaPeloAtribuido,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
        id: json['_id']?.toString() ?? '',
        title: json['titulo']?.toString() ?? '',
        description: json['descricao']?.toString() ?? '',
        completed: json['concluida'] == true,
        deadline: json['dataLimite'] != null &&
                json['dataLimite'].toString().isNotEmpty
            ? DateTime.parse(json['dataLimite'].toString())
            : null,
        status: _parseStatus(json['status']?.toString()),
        priority: json['prioridade'] != null
            ? int.tryParse(json['prioridade'].toString()) ?? 5
            : 5,
        complexidade: json['complexidade']?.toString() ?? '',
        assignedTo: json['atribuicoes'] != null &&
                (json['atribuicoes'] as List).isNotEmpty
            ? (json['atribuicoes'] as List)[0]
                .toString() // Pega o primeiro ID da lista
            : null,
        projectId: json['projeto'] is String
            ? json['projeto']?.toString()
            : (json['projeto'] as Map<String, dynamic>?)?['_id']?.toString(),
        projeto: json['projeto'] is Map<String, dynamic>
            ? Projeto.fromJson(json['projeto'] as Map<String, dynamic>)
            : null,
        criadaPorUser: json['criadaPor'] is Map<String, dynamic>
            ? UserData.fromJson(json['criadaPor'] as Map<String, dynamic>)
            : null,
        aprovadaPorUser: json['aprovadaPor'] is Map<String, dynamic>
            ? UserData.fromJson(json['aprovadaPor'] as Map<String, dynamic>)
            : null,
        tarefasAnteriores: (json['tarefasAnteriores'] as List<dynamic>?)
            ?.map((t) => t.toString())
            .toList(),
        recebidaPeloAtribuido: json['recebidaPeloAtribuido'] as bool?);
  }

  Map<String, dynamic> toJson() {
    return {
      '_id':
          id, // Inclui _id para update/delete se necessário, mas não para criação
      'titulo': title,
      'descricao': description,
      'prioridade': priority.toString(),
      'complexidade': complexidade,
      'projeto': projectId,
      'status': getStatusString(status),
      'dataLimite': deadline?.toIso8601String(),
      'atribuicoes': assignedTo != null ? [assignedTo] : [], // Lista de IDs
      'tarefasAnteriores': tarefasAnteriores,
    };
  }

  static TaskStatus _parseStatus(String? status) {
    if (status == null) return TaskStatus.pending;

    switch (status.toLowerCase()) {
      case 'pending':
      case 'pendente':
        return TaskStatus.pending;
      case 'in_progress':
      case 'inprogress':
      case 'em_andamento':
        return TaskStatus.inProgress;
      case 'completed':
      case 'done':
      case 'concluido':
        return TaskStatus.completed;
      case 'cancelled':
      case 'cancelado':
        return TaskStatus.cancelled;
      case 'approved':
        return TaskStatus
            .completed; // Mapeia approved para completed no frontend
      default:
        return TaskStatus.pending;
    }
  }

  static String getStatusString(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'done';
      case TaskStatus.cancelled:
        return 'cancelled';
    }
  }
}

// Classe para os dados do gráfico de Burndown (e Projeção, pois têm estrutura similar)
class BurndownDataPoint {
  final DateTime date;
  final int pending;
  final int dayIndex;

  BurndownDataPoint({
    required this.date,
    required this.pending,
    required this.dayIndex,
  });

  factory BurndownDataPoint.fromJson(Map<String, dynamic> json, int index) {
    return BurndownDataPoint(
      date: DateTime.parse(json['date'] as String),
      pending: (json['pending'] as num).toInt(),
      dayIndex: index,
    );
  }
}

// Service para interagir com a API de Tarefas
class TaskService {
  static const String _tasksEndpoint = '/tasks';
  // Alterado para a URL de produção/Hospedagem, conforme o cenário.
  // Se estiver testando localmente, mude para 'http://localhost:3000'.
  static const String _baseUrl = 'https://chronos-production-f584.up.railway.app';

  static Future<String?> _getToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await user.getIdToken();
      return token;
    }
    print('TaskService: Usuário não autenticado.');
    return null;
  }

  static Future<String?> getAuthTokenForRecommendation() async {
    return _getToken();
  }

  static TaskStatus parseStatus(String status) {
    return Task._parseStatus(status);
  }

  static String getStatusString(TaskStatus status) {
    return Task.getStatusString(status);
  }

  // Busca todas as tarefas que o usuário logado pode visualizar
  static Future<List<Task>> getTasks() async {
    final String? token = await _getToken();
    if (token == null) {
      print('TaskService (getTasks): Token de autenticação não encontrado.');
      return [];
    }

    final Uri url = Uri.parse('$_baseUrl$_tasksEndpoint');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> tasksList =
            json.decode(utf8.decode(response.bodyBytes));
        return tasksList.map((taskJson) => Task.fromJson(taskJson)).toList();
      } else {
        print(
            'TaskService (getTasks): Erro ao buscar tarefas. Status: ${response.statusCode}, Corpo: ${response.body}');
        return [];
      }
    } catch (e) {
      print('TaskService (getTasks): Exceção ao buscar tarefas: $e');
      return [];
    }
  }

  // Busca tarefas atribuídas ao usuário logado e não confirmadas
  static Future<List<Task>> getMyUnacknowledgedTasks() async {
    final String? token = await _getToken();
    if (token == null) {
      print(
          'TaskService (getMyUnacknowledgedTasks): Token de autenticação não encontrado.');
      return [];
    }

    final Uri url = Uri.parse('$_baseUrl$_tasksEndpoint/my-unacknowledged');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> tasksList =
            json.decode(utf8.decode(response.bodyBytes));
        return tasksList.map((taskJson) => Task.fromJson(taskJson)).toList();
      } else {
        print(
            'TaskService (getMyUnacknowledgedTasks): Erro ao buscar tarefas não confirmadas. Status: ${response.statusCode}, Corpo: ${response.body}');
        return [];
      }
    } catch (e) {
      print(
          'TaskService (getMyUnacknowledgedTasks): Exceção ao buscar tarefas não confirmadas: $e');
      return [];
    }
  }

  // Atualiza uma tarefa existente
  static Future<bool> updateTask(Task task) async {
    final String? token = await _getToken();
    if (token == null) {
      print('TaskService (updateTask): Token de autenticação não encontrado.');
      return false;
    }

    final Uri url = Uri.parse('$_baseUrl$_tasksEndpoint/${task.id}');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(task.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print(
            'TaskService (updateTask): Erro ao atualizar tarefa. Status: ${response.statusCode}, Corpo: ${response.body}');
        return false;
      }
    } catch (e) {
      print('TaskService (updateTask): Exceção ao atualizar tarefa: $e');
      return false;
    }
  }

  // Cria uma nova tarefa
  static Future<bool> createTask(Task task) async {
    final String? token = await _getToken();
    if (token == null) {
      print('TaskService (createTask): Token de autenticação não encontrado.');
      return false;
    }

    final Uri url = Uri.parse('$_baseUrl$_tasksEndpoint');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(task.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Tarefa criada com sucesso! Resposta: ${response.body}');
        return true;
      } else {
        print(
            'TaskService (createTask): Erro ao criar tarefa. Status: ${response.statusCode}, Corpo: ${response.body}');
        return false;
      }
    } catch (e) {
      print('TaskService (createTask): Exceção ao criar tarefa: $e');
      return false;
    }
  }

  // Deleta uma tarefa
  static Future<bool> deleteTask(String taskId) async {
    final String? token = await _getToken();
    if (token == null) {
      print('TaskService (deleteTask): Token de autenticação não encontrado.');
      return false;
    }

    final Uri url = Uri.parse('$_baseUrl$_tasksEndpoint/$taskId');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print(
            'TaskService (deleteTask): Erro ao deletar tarefa. Status: ${response.statusCode}, Corpo: ${response.body}');
        return false;
      }
    } catch (e) {
      print('TaskService (deleteTask): Exceção ao deletar tarefa: $e');
      return false;
    }
  }

  // Confirma o recebimento de uma tarefa pelo usuário atribuído
  static Future<bool> acknowledgeAssignedTask(String taskId) async {
    final String? token = await _getToken();
    if (token == null) {
      print(
          'TaskService (acknowledgeAssignedTask): Token de autenticação não encontrado.');
      return false;
    }

    final Uri url = Uri.parse('$_baseUrl$_tasksEndpoint/$taskId/acknowledge');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({}),
      );

      if (response.statusCode == 200) {
        print('Tarefa $taskId confirmada pelo atribuído com sucesso!');
        return true;
      } else {
        print(
            'TaskService (acknowledgeAssignedTask): Erro ao confirmar recebimento. Status: ${response.statusCode}, Corpo: ${response.body}');
        if (response.statusCode == 403) {
          throw Exception(
              'Você não está atribuído a esta tarefa ou não pode confirmá-la.');
        } else if (response.statusCode == 400) {
          throw Exception(
              'Esta tarefa já foi confirmada ou não está em um estado válido.');
        }
        return false;
      }
    } catch (e) {
      print('TaskService (acknowledgeAssignedTask): Exceção - $e');
      throw Exception('Exceção ao confirmar recebimento: ${e.toString()}');
    }
  }

  // Função para completar as tarefas (com tempo_gasto_horas e code)
  static Future<bool> completeTask(String taskId, String userId,
      double tempoGastoHoras, String? code) async {
    final String? token = await _getToken();
    if (token == null) {
      print(
          'TaskService (completeTask): Token de autenticação não encontrado.');
      return false;
    }

    final Uri url = Uri.parse(
        '$_baseUrl$_tasksEndpoint/$taskId/complete'); // Endpoint no backend

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userId': userId,
          'tempo_gasto_horas': tempoGastoHoras,
          'code': code, // Inclui o campo 'code' no corpo da requisição
        }),
      );

      if (response.statusCode == 200) {
        print('Tarefa $taskId completada com sucesso!');
        return true;
      } else {
        print(
            'TaskService (completeTask): Erro ao completar tarefa. Status: ${response.statusCode}, Corpo: ${response.body}');
        if (response.statusCode == 400) {
          throw Exception(
              'Requisição inválida para completar tarefa: ${response.body}');
        } else if (response.statusCode == 403) {
          throw Exception('Permissão negada para completar esta tarefa.');
        } else if (response.statusCode == 404) {
          throw Exception(
              'Tarefa ou usuário não encontrado ao tentar completar.');
        }
        return false;
      }
    } catch (e) {
      print('TaskService (completeTask): Exceção ao completar tarefa: $e');
      throw Exception('Exceção ao completar tarefa: ${e.toString()}');
    }
  }

  // Busca dados para o gráfico de Burndown
  static Future<List<BurndownDataPoint>> getBurndownData(
      String projectId, DateTime startDateQuery, DateTime endDateQuery) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception(
          'Token de autenticação não encontrado para dados do Burndown.');
    }
    final String startDateString =
        '${startDateQuery.year.toString().padLeft(4, '0')}-'
        '${startDateQuery.month.toString().padLeft(2, '0')}-'
        '${startDateQuery.day.toString().padLeft(2, '0')}';
    final String endDateString =
        '${endDateQuery.year.toString().padLeft(4, '0')}-'
        '${endDateQuery.month.toString().padLeft(2, '0')}-'
        '${endDateQuery.day.toString().padLeft(2, '0')}';

    final Uri url = Uri.parse(
        '$_baseUrl$_tasksEndpoint/burndown/$projectId?start=$startDateString&end=$endDateString'); // ADICIONADO &end

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
        return body
            .asMap()
            .entries
            .map((entry) => BurndownDataPoint.fromJson(
                entry.value as Map<String, dynamic>, entry.key))
            .toList();
      } else {
        print(
            'TaskService (getBurndownData): Erro HTTP ${response.statusCode} - ${response.body}');
        throw Exception(
            'Falha ao carregar dados do burndown. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskService (getBurndownData): Exceção - $e');
      throw Exception('Exceção ao carregar dados do burndown: ${e.toString()}');
    }
  }

// Busca dados para o gráfico de Projeção
  static Future<List<BurndownDataPoint>> getProjectionData(
      String projectId, DateTime startDateQuery, DateTime endDateQuery) async {
    // ADICIONADO endDateQuery
    final token = await _getToken();
    if (token == null) {
      throw Exception(
          'Token de autenticação não encontrado para dados de Projeção.');
    }
    final String startDateString =
        '${startDateQuery.year.toString().padLeft(4, '0')}-'
        '${startDateQuery.month.toString().padLeft(2, '0')}-'
        '${startDateQuery.day.toString().padLeft(2, '0')}';
    final String endDateString =
        '${endDateQuery.year.toString().padLeft(4, '0')}-'
        '${endDateQuery.month.toString().padLeft(2, '0')}-'
        '${endDateQuery.day.toString().padLeft(2, '0')}';

    final Uri url = Uri.parse(
        '$_baseUrl$_tasksEndpoint/projection/$projectId?start=$startDateString&end=$endDateString'); // ADICIONADO &end

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
        return body
            .asMap()
            .entries
            .map((entry) => BurndownDataPoint.fromJson(
                entry.value as Map<String, dynamic>, entry.key))
            .toList();
      } else {
        print(
            'TaskService (getProjectionData): Erro HTTP ${response.statusCode} - ${response.body}');
        throw Exception(
            'Falha ao carregar dados de projeção. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('TaskService (getProjectionData): Exceção - $e');
      throw Exception('Exceção ao carregar dados de projeção: ${e.toString()}');
    }
  }

  // Buscar todas as tarefas atribuídas ao usuário logado (para a Agenda)
  static Future<List<Task>> findAssignedTasksForUser() async {
    final String? token = await _getToken();
    if (token == null) {
      print(
          'TaskService (findAssignedTasksForUser): Token de autenticação não encontrado.');
      return [];
    }

    final Uri url = Uri.parse('$_baseUrl$_tasksEndpoint/my-assigned');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> tasksList =
            json.decode(utf8.decode(response.bodyBytes));
        return tasksList.map((taskJson) => Task.fromJson(taskJson)).toList();
      } else {
        print(
            'TaskService (findAssignedTasksForUser): Erro ao buscar tarefas atribuídas. Status: ${response.statusCode}, Corpo: ${response.body}');
        return [];
      }
    } catch (e) {
      print(
          'TaskService (findAssignedTasksForUser): Exceção ao buscar tarefas atribuídas: $e');
      return [];
    }
  }

  /// NOVO MÉTODO: Busca todas as tarefas relacionadas ao usuário logado (criadas, aprovadas ou atribuídas).
  /// Consome o endpoint GET /tasks/user/:userId do backend.
  static Future<List<Task>> getMyTasks() async {
    final String? token = await _getToken();
    if (token == null) {
      print('TaskService (getMyTasks): Token de autenticação não encontrado.');
      return [];
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid.isEmpty) {
      print('TaskService (getMyTasks): UID do usuário logado não encontrado.');
      return [];
    }
    final String userId = currentUser.uid;

    final Uri url = Uri.parse('$_baseUrl$_tasksEndpoint/user/$userId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> tasksList =
            json.decode(utf8.decode(response.bodyBytes));
        return tasksList.map((taskJson) => Task.fromJson(taskJson)).toList();
      } else {
        print(
            'TaskService (getMyTasks): Erro ao buscar minhas tarefas. Status: ${response.statusCode}, Corpo: ${utf8.decode(response.bodyBytes)}');
        throw Exception(
            'Falha ao carregar minhas tarefas: ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print('TaskService (getMyTasks): Exceção ao buscar minhas tarefas: $e');
      throw Exception('Exceção ao buscar minhas tarefas: ${e.toString()}');
    }
  }

  /// NOVO MÉTODO: Envia avaliação de código para uma tarefa (frontend).
  static Future<dynamic> reviewTaskUser(
      String taskId,
      String assignedUserId,
      String comentario,
      double nota,
      String? codigo,
      String reviewerUserId) async {
    final String? token = await _getToken();
    if (token == null) {
      print(
          'TaskService (reviewTaskUser): Token de autenticação não encontrado.');
      throw Exception('Token de autenticação não encontrado.');
    }

    final Uri url =
        Uri.parse('$_baseUrl$_tasksEndpoint/$taskId/review/$assignedUserId');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'comentario': comentario,
          'nota': nota,
          'codigo': codigo,
          // 'reviewerUserId': reviewerUserId // O backend pega o reviewerUserId do token, não do body
        }),
      );

      if (response.statusCode == 200) {
        print(
            'Avaliação de tarefa $taskId enviada com sucesso! Resposta: ${response.body}');
        // Retorna o corpo da resposta ou um valor booleano de sucesso
        return true;
      } else {
        print(
            'TaskService (reviewTaskUser): Erro ao avaliar tarefa. Status: ${response.statusCode}, Corpo: ${response.body}');
        throw Exception(
            'Falha ao avaliar tarefa: ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print('TaskService (reviewTaskUser): Exceção ao avaliar tarefa: $e');
      throw Exception('Exceção ao avaliar tarefa: ${e.toString()}');
    }
  }

  // NOVO MÉTODO: Busca tarefas de um projeto que estão atribuídas a um usuário logado
  // e cujo status é 'pending' ou 'in_progress'.
  static Future<List<Task>> findActiveAssignedTasksInProject(
      String projectId) async {
    final String? token = await _getToken();
    if (token == null) {
      print(
          'TaskService (findActiveAssignedTasksInProject): Token de autenticação não encontrado.');
      return [];
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid.isEmpty) {
      print(
          'TaskService (findActiveAssignedTasksInProject): UID do usuário logado não encontrado.');
      return [];
    }

    final Uri url = Uri.parse(
        '$_baseUrl$_tasksEndpoint/$projectId/my-active-assigned'); // Endpoint no backend

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> tasksList =
            json.decode(utf8.decode(response.bodyBytes));
        return tasksList.map((taskJson) => Task.fromJson(taskJson)).toList();
      } else {
        print(
            'TaskService (findActiveAssignedTasksInProject): Erro ao buscar tarefas. Status: ${response.statusCode}, Corpo: ${utf8.decode(response.bodyBytes)}');
        throw Exception(
            'Falha ao carregar tarefas ativas e atribuídas: ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print(
          'TaskService (findActiveAssignedTasksInProject): Exceção ao buscar tarefas: $e');
      throw Exception(
          'Exceção ao buscar tarefas ativas e atribuídas: ${e.toString()}');
    }
  }
}
