import 'package:flutter/material.dart';
import 'package:code/common/constants/app_colors.dart';
import 'package:code/components/mobile_layout.dart'; // Importa o MobileLayout
import 'package:code/services/task_service.dart'; // Importa o TaskService
import 'package:intl/intl.dart'; // Para formatação de data

class NotificationMobilePage extends StatefulWidget {
  const NotificationMobilePage({super.key});

  @override
  State<NotificationMobilePage> createState() => _NotificationMobilePageState();
}

class _NotificationMobilePageState extends State<NotificationMobilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Task> _tasksDueSoon = [];
  bool _isLoadingDueSoon = true;
  String? _errorDueSoon;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTasksDueSoon(); // Inicia a busca por tarefas prestes a vencer
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTasksDueSoon() async {
    setState(() {
      _isLoadingDueSoon = true;
      _errorDueSoon = null;
    });
    try {
      final DateTime oneWeekFromNow =
          DateTime.now().add(const Duration(days: 7));
      final List<Task> fetchedTasks =
          await TaskService.getTasks(); // Obtém todas as tarefas

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
    // Conteúdo da aba "Próximo Vencimento"
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
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    return MobileLayout(
      title: 'Notificações', // Título para a AppBar mobile
      // Adiciona as Tabs diretamente na AppBar do MobileLayout
      // O MobileLayout já tem uma AppBar. Precisamos passá-la para o `bottom` da AppBar
      // ou recriar a AppBar dentro deste MobileLayout.
      // A forma mais simples para um MobileLayout que tem um child é colocar a TabBar dentro do corpo,
      // ou ter uma AppBar customizada que inclua a TabBar (menos comum para MobileLayout genérico).
      // Vamos usar a opção de ter a TabBar no corpo e a AppBar do MobileLayout para o título.
      // Se você quiser a TabBar *na* AppBar, o MobileLayout precisaria de um parâmetro `bottomWidget`.
      // Por enquanto, vou colocar as Tabs abaixo da AppBar.

      // Opção 1: Tabs no corpo
      child: Column(
        children: [
          TabBar(
            // TabBar dentro do corpo da página
            controller: _tabController,
            labelColor: AppColors.primary, // Use cores do tema
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.secondary,
            tabs: const [
              Tab(text: 'Próximo Vencimento'),
              Tab(text: 'Atividades Recentes'),
              Tab(text: 'Alertas Personalizados'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDueSoonTabContent(),
                const Center(
                    child: Text(
                        'Conteúdo da aba "Atividades Recentes" (Placeholder)')),
                const Center(
                    child: Text(
                        'Conteúdo da aba "Alertas Personalizados" (Placeholder)')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
