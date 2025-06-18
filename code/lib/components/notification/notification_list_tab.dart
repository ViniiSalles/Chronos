import 'package:flutter/material.dart';
import 'package:code/common/constants/app_colors.dart';
import 'package:code/servicesMobile/notification_service.dart'; // Importa o NotificationService
import 'package:intl/intl.dart'; // Para formatação de data

class NotificationListTab extends StatefulWidget {
  final VoidCallback?
      onNotificationsUpdated; // Callback para quando notificações são lidas

  const NotificationListTab({super.key, this.onNotificationsUpdated});

  @override
  State<NotificationListTab> createState() => _NotificationListTabState();
}

class _NotificationListTabState extends State<NotificationListTab> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Busca todas as notificações do usuário logado (sem filtro inicial)
      final fetchedNotifications =
          await NotificationService.getMyNotifications();
      if (!mounted) return;

      setState(() {
        _notifications = fetchedNotifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao carregar notificações: ${e.toString()}';
        _isLoading = false;
      });
      print('Erro ao buscar notificações: $e');
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final success =
          await NotificationService.markNotificationAsRead(notificationId);
      if (!mounted) return;

      if (success) {
        // Atualiza o estado da notificação localmente para refletir a mudança
        setState(() {
          final index =
              _notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            _notifications[index] = AppNotification(
              id: _notifications[index].id,
              message: _notifications[index].message,
              eventType: _notifications[index].eventType,
              recipientId: _notifications[index].recipientId,
              relatedToId: _notifications[index].relatedToId,
              relatedToModel: _notifications[index].relatedToModel,
              read: true, // Marca como lida
              createdAt: _notifications[index].createdAt,
              readAt: DateTime.now(), // Define a data de leitura
            );
          }
        });
        widget.onNotificationsUpdated
            ?.call(); // Notifica o pai para, talvez, atualizar contagem de não lidas
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Falha ao marcar notificação como lida.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao marcar como lida: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.error),
        ),
      ));
    } else if (_notifications.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Nenhuma notificação encontrada.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ));
    } else {
      return ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: notification.read
                ? Colors.grey[100]
                : AppColors.surface, // Destaca não lidas
            child: ListTile(
              leading: Icon(
                _getNotificationIcon(notification.eventType),
                color: notification.read
                    ? AppColors.textSecondary
                    : AppColors.primary,
              ),
              title: Text(
                notification.message,
                style: TextStyle(
                  fontWeight:
                      notification.read ? FontWeight.normal : FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              subtitle: Text(
                '${DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt)}${notification.read ? ' (Lida)' : ''}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              trailing: !notification
                      .read // Mostrar botão "Marcar como lida" apenas se não estiver lida
                  ? TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => _markAsRead(notification.id),
                      child: const Text('Marcar como lida',
                          style: TextStyle(color: AppColors.primary)),
                    )
                  : null, // Não mostra botão se já lida
              onTap: () {
                // Ao clicar, se não estiver lida, marca como lida
                if (!notification.read) {
                  _markAsRead(notification.id);
                }
                // TODO: Implementar navegação para o item relacionado (tarefa, projeto, reunião)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Clicou na notificação: ${notification.message}')),
                );
              },
            ),
          );
        },
      );
    }
  }

  // Função auxiliar para determinar o ícone da notificação
  IconData _getNotificationIcon(String eventType) {
    switch (eventType) {
      case 'TASK_UPDATED':
      case 'TASK_ASSIGNED':
      case 'TASK_STATUS_CHANGED':
        return Icons.task_alt;
      case 'TASK_COMPLETED':
        return Icons.check_circle;
      case 'TASK_ACKNOWLEDGEMENT':
        return Icons.verified;
      case 'TASK_REVIEWED':
        return Icons.rate_review;
      case 'PROJECT_UPDATED':
      case 'PROJECT_MEMBER_ADDED':
        return Icons.folder;
      case 'MEETING_CREATED':
      case 'MEETING_UPDATED':
      case 'MEETING_NEAR_START':
        return Icons.meeting_room;
      default:
        return Icons.info_outline;
    }
  }
}
