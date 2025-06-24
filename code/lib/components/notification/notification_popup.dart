import 'package:code/components/notification/unconfirmed_tasks.dart';
import 'package:code/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:code/common/constants/app_colors.dart';
import 'package:code/services/task_service.dart';
import 'package:intl/intl.dart';
import 'package:code/components/notification/notification_list_tab.dart'; // IMPORTANTE: Importe o novo componente

class NotificationPopup extends StatefulWidget {
  const NotificationPopup({super.key});

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // _tasksDueSoon, _isLoadingDueSoon, _errorDueSoon: Mantidos se ainda precisar deles na primeira aba
  // Se a primeira aba for apenas NotificationListTab, você pode remover estes aqui.
  List<Task> _tasksDueSoon = [];
  bool _isLoadingDueSoon = true;
  String? _errorDueSoon;

  // Contador para notificações não lidas (opcional)
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTasksDueSoon(); // Pode ser mantido para a primeira aba, ou removido se a NotificationListTab for genérica.
    _updateUnreadCount(); // Tenta buscar a contagem inicial de não lidas
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Adicionado para atualizar a contagem de notificações não lidas
  Future<void> _updateUnreadCount() async {
    try {
      final unread = await NotificationService.getMyNotifications(read: false);
      if (!mounted) return;
      setState(() {
        _unreadNotificationsCount = unread.length;
      });
    } catch (e) {
      print('Erro ao atualizar contagem de não lidas: $e');
    }
  }

  Future<void> _fetchTasksDueSoon() async {
    setState(() {
      _isLoadingDueSoon = true;
      _errorDueSoon = null;
    });
    try {
      final DateTime oneWeekFromNow =
          DateTime.now().add(const Duration(days: 7));
      final List<Task> fetchedTasks = await TaskService.getTasks();

      if (!mounted) return;

      _tasksDueSoon = fetchedTasks.where((task) {
        if (task.deadline == null) return false;
        if (task.status == TaskStatus.completed ||
            task.status == TaskStatus.cancelled) {
          return false;
        }

        return task.deadline!
                .isAfter(DateTime.now().subtract(const Duration(days: 1))) &&
            task.deadline!.isBefore(oneWeekFromNow);
      }).toList();

      setState(() {
        _isLoadingDueSoon = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorDueSoon = 'Erro ao carregar tarefas: ${e.toString()}';
        _isLoadingDueSoon = false;
      });
      print('Erro ao buscar tarefas próximas do vencimento: $e');
    }
  }

  Widget _buildDueSoonTabContent() {
    if (_isLoadingDueSoon) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorDueSoon != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _errorDueSoon!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.error),
        ),
      ));
    } else if (_tasksDueSoon.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Nenhuma tarefa com vencimento próximo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ));
    } else {
      return ListView.builder(
        itemCount: _tasksDueSoon.length,
        itemBuilder: (context, index) {
          final task = _tasksDueSoon[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Theme.of(context).cardColor,
            child: ListTile(
              title: Text(
                task.title,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              subtitle: Text(
                'Projeto: ${task.projeto?.nome ?? 'N/A'} - Vence em: ${task.deadline != null ? DateFormat('dd/MM').format(task.deadline!) : 'N/A'}',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              trailing: Icon(
                Icons.warning,
                color: task.deadline != null &&
                        task.deadline!.isBefore(
                            DateTime.now().add(const Duration(days: 3)))
                    ? AppColors.error
                    : AppColors.warning,
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Clicou na tarefa: ${task.title}')),
                );
              },
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 600,
        height: 500,
        child: Scaffold(
          backgroundColor: Theme.of(context).cardColor,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: Text(
                'Notificações ($_unreadNotificationsCount não lidas)'), // Exibe contagem
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              indicatorColor: AppColors.secondary,
              tabs: const [
                Tab(text: 'Próximo Vencimento'),
                Tab(text: 'Tarefas Não Confirmadas'),
                Tab(text: 'Todas as Notificações'), // NOVA ABA AQUI
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDueSoonTabContent(), // Aba 1: Próximo Vencimento
                    UnconfirmedTasksTab(
                      onTaskAcknowledged: () {
                        _fetchTasksDueSoon(); // Recarrega se uma tarefa for confirmada
                        _updateUnreadCount(); // Recarrega contagem de não lidas
                      },
                    ),
                    NotificationListTab(
                      // NOVA ABA: Todas as Notificações
                      onNotificationsUpdated:
                          _updateUnreadCount, // Atualiza a contagem de não lidas
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await NotificationService
                            .markAllNotificationsAsRead(); // Marca todas como lidas
                        _updateUnreadCount(); // Atualiza a contagem
                        // Opcional: Recarregar NotificationListTab se ela mostrava apenas não lidas
                        // ou fechar o popup
                        Navigator.of(context).pop();
                      },
                      child: const Text('Marcar todas como lidas',
                          style: TextStyle(color: AppColors.primary)),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fechar',
                          style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
