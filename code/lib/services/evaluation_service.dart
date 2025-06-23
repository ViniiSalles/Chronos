import 'dart:convert';
import 'package:http/http.dart' as http;
import './api_service.dart';

class EvaluatableTask {
  final String id;
  final String titulo;
  final String? usuarioNome;
  final Evaluation? avaliacao;
  final Function onEvaluationSubmitted;

  EvaluatableTask({
    required this.id,
    required this.titulo,
    this.usuarioNome,
    this.avaliacao,
    required this.onEvaluationSubmitted,
  });

  // MÉTODO fromJson FINAL - adaptado para a resposta do backend
  factory EvaluatableTask.fromJson(
      Map<String, dynamic> json, Function onEvaluationSubmitted) {
    String? finalUsuarioNome = 'Não atribuído';
    // O backend agora retorna o campo 'atribuicoes' populado.
    // Extraímos o nome do primeiro usuário da lista.
    if (json['atribuicoes'] is List &&
        (json['atribuicoes'] as List).isNotEmpty) {
      final firstUser = (json['atribuicoes'] as List).first;
      if (firstUser is Map && firstUser['nome'] != null) {
        finalUsuarioNome = firstUser['nome'];
      }
    }

    // O backend agora retorna o campo 'avaliacaoId' populado.
    final avaliacaoJson = json['avaliacaoId'];

    return EvaluatableTask(
      id: json['_id']?.toString() ?? '',
      titulo: json['titulo'] ?? 'Título indisponível',
      usuarioNome: finalUsuarioNome,
      // Verifica se os dados da avaliação existem antes de criar o objeto.
      avaliacao: avaliacaoJson != null && avaliacaoJson is Map<String, dynamic>
          ? Evaluation.fromJson(avaliacaoJson)
          : null,
      onEvaluationSubmitted: onEvaluationSubmitted,
    );
  }
}

class Evaluation {
  final double nota;
  final String comentario;

  Evaluation({required this.nota, required this.comentario});

  // MÉTODO fromJson FINAL - adaptado para a resposta do backend
  factory Evaluation.fromJson(Map<String, dynamic> json) {
    return Evaluation(
      nota: (json['nota'] as num).toDouble(),
      // O backend retorna o campo 'code', que mapeamos para 'comentario'.
      comentario: json['code'] ?? '',
    );
  }
}

class EvaluationService {
  final ApiService _apiService = ApiService();

  Future<List<EvaluatableTask>> getCompletedTasks(
      String projectId, Function onEvaluationSubmitted) async {
    try {
      final dynamic responseData =
          await ApiService.get('tasks/completed/$projectId');

      if (responseData is List) {
        return responseData
            .map((dynamic item) =>
                EvaluatableTask.fromJson(item, onEvaluationSubmitted))
            .toList();
      } else {
        throw Exception('Formato de resposta da API inesperado.');
      }
    } catch (e) {
      print('Exceção ao carregar tarefas: $e.');
      return []; // Retorna lista vazia em caso de erro
    }
  }

  // ====================================================================
  // MÉTODO submitEvaluation CORRIGIDO
  // ====================================================================
  Future<bool> submitEvaluation({
    required String taskId,
    required double rating,
    required String comment,
  }) async {
    try {
      // ou lança uma exceção em caso de erro.
      final dynamic responseData = await ApiService.post('tasks/evaluate', {
        'taskId': taskId,
        'nota': rating,
        'comentario': comment,
      });

      // Se a chamada não lançou uma exceção e retornou algo, consideramos sucesso.
      if (responseData != null) {
        return true;
      } else {
        // Isso pode acontecer se a API retornar um 2xx sem corpo de resposta.
        // Se o seu ApiService retornar nulo nesses casos, isto ainda significa sucesso.
        return true;
      }
    } catch (e) {
      // O catch irá capturar erros de rede ou respostas HTTP de erro (4xx, 5xx)
      // se o seu ApiService for projetado para lançar exceções nesses casos.
      print('Erro ao enviar avaliação: $e');
      return false;
    }
  }
}
