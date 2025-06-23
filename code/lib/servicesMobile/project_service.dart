import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class Project {
  final String id;
  final String nome;
  final String? descricao;
  final DateTime dataInicio;
  final DateTime dataFim;
  final bool status;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> users;
  String? token;

  Project({
    this.id = '',
    required this.nome,
    this.descricao,
    required this.dataInicio,
    required this.dataFim,
    required this.status,
    this.tasks = const [],
    this.users = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString(),
      dataInicio: DateTime.parse(json['dataInicio']?.toString() ??
          json['data_inicio']?.toString() ??
          DateTime.now().toIso8601String()),
      dataFim: DateTime.parse(
          json['data_fim']?.toString() ?? DateTime.now().toIso8601String()),
      status: json['status']?.toString().toLowerCase() == 'ativo',
      tasks: List<Map<String, dynamic>>.from(json['tasks'] ?? []),
      users: (json['users'] as List<dynamic>?)
              ?.map((u) => u as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nome': nome,
      'dataInicio':
          dataInicio.toIso8601String().split('T')[0], // Envia apenas a data
      'data_fim':
          dataFim.toIso8601String().split('T')[0], // Envia apenas a data
      'status': status ? 'ativo' : 'inativo',
    };

    if (descricao != null) {
      data['descricao'] = descricao;
    }

    return data;
  }
}

class ProjectService {
  static const String _baseUrl = 'http://10.0.2.2:3000';
  static const String _projectControllerPath = '/project';

  static Future<String?> _getToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await user.getIdToken();
      return token;
    }
    print('ProjectService: Usuário não autenticado.');
    return null;
  }

  // Método para criar um novo projeto (POST)
  static Future<Project?> createProject(Project project) async {
    final String? token = await _getToken();
    if (token == null) {
      print(
          'ProjectService (createProject): Token de autenticação não encontrado.');
      return null;
    }

    project.token = token;

    final Uri url = Uri.parse('$_baseUrl$_projectControllerPath');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(project.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData =
              json.decode(utf8.decode(response.bodyBytes));
          return Project.fromJson(responseData);
        } catch (e) {
          print(
              'ProjectService (createProject): Erro ao decodificar resposta: $e');
          return null;
        }
      } else {
        print(
            'ProjectService (createProject): Erro ao criar projeto. Status: ${response.statusCode}, Corpo: ${response.body}');
        return null;
      }
    } catch (e) {
      print('ProjectService (createProject): Exceção ao criar projeto: $e');
      return null;
    }
  }

  // Método para atualizar um projeto existente (PUT)
  static Future<Project?> updateProject(Project project) async {
    if (project.id.isEmpty) {
      print(
          'ProjectService (updateProject): ID do projeto é necessário para atualização.');
      return null;
    }

    final String? token = await _getToken();
    if (token == null) {
      print(
          'ProjectService (updateProject): Token de autenticação não encontrado.');
      return null;
    }

    final Uri url = Uri.parse('$_baseUrl$_projectControllerPath/${project.id}');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(project.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            json.decode(utf8.decode(response.bodyBytes));
        return Project.fromJson(responseData);
      } else {
        print(
            'ProjectService (updateProject): Erro ao atualizar projeto. Status: ${response.statusCode}, Corpo: ${response.body}');
        return null;
      }
    } catch (e) {
      print('ProjectService (updateProject): Exceção ao atualizar projeto: $e');
      return null;
    }
  }

  // Método para buscar projetos do usuário logado (my-projects)
  static Future<List<Project>> getMyProjects() async {
    final String? token = await _getToken();
    if (token == null) {
      print(
          'ProjectService (getMyProjects): Token de autenticação não encontrado.');
      return [];
    }

    final Uri url = Uri.parse('$_baseUrl$_projectControllerPath/my-projects');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData =
            json.decode(utf8.decode(response.bodyBytes));
        return responseData
            .map((projectJson) =>
                Project.fromJson(projectJson as Map<String, dynamic>))
            .toList();
      } else {
        print(
            'ProjectService (getMyProjects): Erro ao buscar "meus projetos". Status: ${response.statusCode}, Corpo: ${response.body}');
        return [];
      }
    } catch (e) {
      print(
          'ProjectService (getMyProjects): Exceção ao buscar "meus projetos": $e');
      return [];
    }
  }

  // Método para buscar todos os projetos (GET)
  static Future<List<Project>> getProjects() async {
    final String? token = await _getToken();
    if (token == null) {
      print(
          'ProjectService (getProjects): Token de autenticação não encontrado.');
      return [];
    }

    final Uri url = Uri.parse('$_baseUrl$_projectControllerPath');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> projectList =
            json.decode(utf8.decode(response.bodyBytes));
        return projectList
            .map((project) => Project.fromJson(project as Map<String, dynamic>))
            .toList();
      } else {
        print(
            'ProjectService (getProjects): Erro ao buscar todos os projetos. Status: ${response.statusCode}, Corpo: ${response.body}');
        return [];
      }
    } catch (e) {
      print(
          'ProjectService (getProjects): Exceção ao buscar todos os projetos: $e');
      return [];
    }
  }

  // Método para buscar um projeto por ID (GET /project/:id)
  static Future<Project?> getProjectById(String projectId) async {
    if (projectId.isEmpty) {
      print('ProjectService (getProjectById): ID do projeto é necessário.');
      return null;
    }

    final String? token = await _getToken();
    if (token == null) {
      print(
          'ProjectService (getProjectById): Token de autenticação não encontrado.');
      return null;
    }

    final Uri url = Uri.parse('$_baseUrl$_projectControllerPath/$projectId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            json.decode(utf8.decode(response.bodyBytes));
        return Project.fromJson(responseData);
      } else {
        print(
            'ProjectService (getProjectById): Erro ao buscar projeto por ID. Status: ${response.statusCode}, Corpo: ${response.body}');
        return null;
      }
    } catch (e) {
      print(
          'ProjectService (getProjectById): Exceção ao buscar projeto por ID: $e');
      return null;
    }
  }

  // Método para deletar um projeto (DELETE)
  static Future<bool> deleteProject(String id) async {
    if (id.isEmpty) {
      print('ProjectService (deleteProject): ID do projeto é necessário.');
      return false;
    }
    final String? token = await _getToken();
    if (token == null) {
      print(
          'ProjectService (deleteProject): Token de autenticação não encontrado.');
      return false;
    }

    final Uri url = Uri.parse('$_baseUrl$_projectControllerPath/$id');

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
            'ProjectService (deleteProject): Erro ao deletar projeto. Status: ${response.statusCode}, Corpo: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ProjectService (deleteProject): Exceção ao deletar projeto: $e');
      return false;
    }
  }

  // Método para verificar o papel do usuário em um projeto
  Future<String?> getMyRoleInProject(String projectId) async {
    final String? token = await _getToken();
    if (token == null) {
      print(
          'ProjectService (getProjectById): Token de autenticação não encontrado.');
      return null;
    }

    if (projectId.isEmpty) {
      return null;
    }

    final Uri url =
        Uri.parse('$_baseUrl$_projectControllerPath/$projectId/my-role');

    try {
      // Chama o novo endpoint seguro.
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final Map<String, dynamic> responseData =
            json.decode(utf8.decode(response.bodyBytes));
        return responseData['role'];
      }
      return null;
    } catch (e) {
      print('Erro ao verificar o papel do usuário: $e');
      return null;
    }
  }
}
