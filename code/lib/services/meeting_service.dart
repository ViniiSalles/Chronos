// lib/services/meeting_service.dart

import 'dart:convert'; // Para jsonEncode, jsonDecode e utf8
import 'package:code/pages/web/agenda_page.dart';
import 'package:http/http.dart' as http; // Para fazer requisições HTTP
import 'package:firebase_auth/firebase_auth.dart'; // Para autenticação Firebase

// Importe a classe Meeting (e MeetingType) do seu modelo centralizado ou da página de agenda
// Se você tem um arquivo lib/models/meeting.dart, importe de lá.
// Caso contrário, use a definição que está em lib/pages/agenda_page.dart

class MeetingService {
  static const String _meetingsEndpoint = '/meetings';
  static const String _baseUrl =
      'https://chronos-production-f584.up.railway.app'; // Sua URL base do backend

  // Método auxiliar para obter o token de autenticação Firebase
  static Future<String?> _getToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    print('MeetingService: Usuário não autenticado.');
    return null;
  }

  // Método para criar uma nova reunião no backend
  static Future<bool> createMeeting(Meeting meeting) async {
    final String? token = await _getToken(); // Obtém o token de autenticação
    if (token == null) {
      print(
          'MeetingService (createMeeting): Token de autenticação não encontrado.');
      return false;
    }

    final Uri url = Uri.parse(
        '$_baseUrl$_meetingsEndpoint'); // URL para o endpoint de criação

    try {
      // Prepara o corpo da requisição JSON, convertendo o objeto Meeting
      final Map<String, dynamic> body = {
        'title': meeting.title,
        'description': meeting.description,
        'project': meeting.projectId, // ID do projeto como string
        'startTime':
            meeting.startTime.toIso8601String(), // Formato ISO 8601 para datas
        'endTime': meeting.endTime.toIso8601String(),
        'location': meeting.location,
        // CORREÇÃO: Usar função auxiliar para mapear o enum para a string exata do backend
        'type': _getMeetingTypeBackendValue(meeting.type),
        'participants':
            meeting.participants, // Lista de IDs de participantes (string[])
        'minutes': meeting.minutes,
      };

      // Realiza a requisição POST
      final response = await http.post(
        url,
        headers: {
          'Content-Type':
              'application/json; charset=UTF-8', // Cabeçalho obrigatório para JSON
          'Authorization':
              'Bearer $token', // Cabeçalho de autorização com o token JWT
        },
        body: json.encode(body), // Converte o Map para uma string JSON
      );

      // Verifica o status da resposta
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Reunião criada com sucesso! Resposta: ${response.body}');
        return true; // Retorna true em caso de sucesso
      } else {
        // Imprime detalhes do erro se a requisição não for bem-sucedida
        print(
            'MeetingService (createMeeting): Erro ao criar reunião. Status: ${response.statusCode}, Corpo: ${response.body}');
        // Lança exceções para serem capturadas e tratadas na UI
        if (response.statusCode == 403) {
          throw Exception(
              'Permissão negada. Apenas o Scrum Master do projeto pode criar reuniões.');
        } else if (response.statusCode == 400) {
          throw Exception(
              'Dados inválidos para a reunião: ${utf8.decode(response.bodyBytes)}'); // Decodifica para melhor visualização do erro do backend
        }
        return false; // Retorna false em caso de falha genérica
      }
    } catch (e) {
      // Captura e imprime exceções (erro de rede, etc.)
      print('MeetingService (createMeeting): Exceção ao criar reunião: $e');
      throw Exception(
          'Exceção ao criar reunião: ${e.toString()}'); // Relança como uma exceção mais amigável
    }
  }

  // NOVA FUNÇÃO AUXILIAR para mapear MeetingType do Dart para a string esperada pelo backend
  static String _getMeetingTypeBackendValue(MeetingType type) {
    switch (type) {
      case MeetingType.DAILY_SCRUM:
        return 'Daily Scrum';
      case MeetingType.SPRINT_PLANNING:
        return 'Sprint Planning';
      case MeetingType.SPRINT_REVIEW:
        return 'Sprint Review';
      case MeetingType.SPRINT_RETROSPECTIVE:
        return 'Sprint Retrospective';
      case MeetingType.REFINEMENT:
        return 'Refinement';
      case MeetingType.OTHER:
        return 'Other';
      default: // Para garantir que todos os casos sejam cobertos
        return 'Other';
    }
  }

  // Método para buscar todas as reuniões para o usuário logado
  static Future<List<Meeting>> getAllMeetingsForUser(String userId) async {
    final String? token = await _getToken();
    if (token == null) {
      print(
          'MeetingService (getAllMeetingsForUser): Token de autenticação não encontrado.');
      return [];
    }

    final Uri url = Uri.parse(
        '$_baseUrl$_meetingsEndpoint'); // Endpoint que retorna reuniões do usuário

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> meetingsList =
            json.decode(utf8.decode(response.bodyBytes));
        return meetingsList.map((json) => Meeting.fromJson(json)).toList();
      } else {
        print(
            'MeetingService (getAllMeetingsForUser): Erro ao buscar reuniões. Status: ${response.statusCode}, Corpo: ${response.body}');
        return [];
      }
    } catch (e) {
      print(
          'MeetingService (getAllMeetingsForUser): Exceção ao buscar reuniões: $e');
      return [];
    }
  }
}
