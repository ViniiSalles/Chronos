import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

// Exemplo de um modelo de Notificação simplificado para o frontend
class AppNotification {
  final String id;
  final String message;
  final String eventType;
  final String recipientId;
  final String? relatedToId;
  final String? relatedToModel;
  final bool read;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.message,
    required this.eventType,
    required this.recipientId,
    this.relatedToId,
    this.relatedToModel,
    required this.read,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? 'Mensagem Indisponível',
      eventType: json['eventType']?.toString() ?? 'UNKNOWN',
      recipientId: json['recipient']?.toString() ??
          '', // Assumindo que recipient é o ID do usuário
      relatedToId: json['relatedToId']?.toString(),
      relatedToModel: json['relatedToModel']?.toString(),
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(
          json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'].toString())
          : null,
    );
  }
}

class NotificationService {
  static const String _notificationsEndpoint = '/notifications';
  static const String _baseUrl =
      'https://chronos-production-f584.up.railway.app'; // Sua URL base do backend

  static Future<String?> _getToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await user.getIdToken();
      return token;
    }
    print('NotificationService: Usuário não autenticado.');
    return null;
  }

  /// Busca todas as notificações para o usuário logado.
  /// Pode filtrar por notificações lidas ou não lidas.
  /// @param read true para lidas, false para não lidas, null para todas.
  static Future<List<AppNotification>> getMyNotifications({bool? read}) async {
    final String? token = await _getToken();
    if (token == null) {
      print(
          'NotificationService (getMyNotifications): Token de autenticação não encontrado.');
      return [];
    }

    Uri url;
    if (read != null) {
      url = Uri.parse('$_baseUrl$_notificationsEndpoint?read=$read');
    } else {
      url = Uri.parse('$_baseUrl$_notificationsEndpoint');
    }

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData =
            json.decode(utf8.decode(response.bodyBytes));
        return responseData
            .map((json) => AppNotification.fromJson(json))
            .toList();
      } else {
        print(
            'NotificationService (getMyNotifications): Erro ao buscar notificações. Status: ${response.statusCode}, Corpo: ${response.body}');
        throw Exception(
            'Falha ao carregar notificações: ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print(
          'NotificationService (getMyNotifications): Exceção ao buscar notificações: $e');
      throw Exception('Exceção ao buscar notificações: ${e.toString()}');
    }
  }

  /// Marca uma notificação específica como lida.
  static Future<bool> markNotificationAsRead(String notificationId) async {
    final String? token = await _getToken();
    if (token == null) {
      print(
          'NotificationService (markNotificationAsRead): Token de autenticação não encontrado.');
      return false;
    }

    final Uri url =
        Uri.parse('$_baseUrl$_notificationsEndpoint/$notificationId/read');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(
            {}), // PATCH geralmente envia corpo vazio ou { "read": true }
      );

      if (response.statusCode == 200) {
        print('Notificação $notificationId marcada como lida com sucesso!');
        return true;
      } else {
        print(
            'NotificationService (markNotificationAsRead): Erro ao marcar como lida. Status: ${response.statusCode}, Corpo: ${response.body}');
        throw Exception(
            'Falha ao marcar notificação como lida: ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print(
          'NotificationService (markNotificationAsRead): Exceção ao marcar como lida: $e');
      throw Exception(
          'Exceção ao marcar notificação como lida: ${e.toString()}');
    }
  }

  /// Marca todas as notificações não lidas do usuário logado como lidas.
  static Future<bool> markAllNotificationsAsRead() async {
    final String? token = await _getToken();
    if (token == null) {
      print(
          'NotificationService (markAllNotificationsAsRead): Token de autenticação não encontrado.');
      return false;
    }

    final Uri url =
        Uri.parse('$_baseUrl$_notificationsEndpoint/mark-all-as-read');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({}),
      );

      if (response.statusCode == 200) {
        print('Todas as notificações marcadas como lidas com sucesso!');
        return true;
      } else {
        print(
            'NotificationService (markAllNotificationsAsRead): Erro ao marcar todas como lidas. Status: ${response.statusCode}, Corpo: ${response.body}');
        throw Exception(
            'Falha ao marcar todas as notificações como lidas: ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print(
          'NotificationService (markAllNotificationsAsRead): Exceção ao marcar todas como lidas: $e');
      throw Exception(
          'Exceção ao marcar todas as notificações como lidas: ${e.toString()}');
    }
  }

  // Você pode adicionar mais métodos aqui conforme a necessidade (ex: deleteNotification)
}
