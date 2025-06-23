import 'package:flutter/material.dart';
import 'package:code/common/constants/app_colors.dart';
import 'package:code/servicesMobile/task_service.dart';

class UnconfirmedTasksTab extends StatefulWidget {
  // Callback para recarregar as notificações após uma confirmação
  final VoidCallback? onTaskAcknowledged;

  const UnconfirmedTasksTab({super.key, this.onTaskAcknowledged});

  @override
  State<UnconfirmedTasksTab> createState() => _UnconfirmedTasksTabState();
}

class _UnconfirmedTasksTabState extends State<UnconfirmedTasksTab> {
  List<Task> _unconfirmedTasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUnconfirmedTasks();
  }

  Future<void> _fetchUnconfirmedTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final fetchedTasks = await TaskService.getTasks(); // Busca todas as tarefas
      if (!mounted) return;

      // Filtra as tarefas que são atribuídas ao usuário logado e não confirmadas
      // (Esta filtragem seria melhor se o backend já retornasse filtrado)
      // Mas para o seu backend atual, vamos pegar tudo e filtrar no frontend por enquanto.
      // Se você implementar `getTasksByAssignedUserAndUnacknowledged` no TaskService (frontend) e backend, use ele.
      
      // Assumindo que TaskService.getTasks() pode retornar todas as tarefas do usuário logado
      // e que o campo 'recebidaPeloAtribuido' virá no Task model.
      
      // O ideal é que `TaskService.getTasks()` seja substituído por um método que chama o novo endpoint do backend:
      // final fetchedTasks = await TaskService.getMyUnacknowledgedTasks();

      // Temporariamente, vou usar a lógica de filtragem da TaskService.getTasks() e o novo endpoint:
      final List<Task> fetchedUnacknowledgedTasks = await TaskService.getMyUnacknowledgedTasks(); // NOVO MÉTODO NO FRONTEND TASKSERVICE


      setState(() {
        _unconfirmedTasks = fetchedUnacknowledgedTasks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao carregar tarefas: ${e.toString()}';
        _isLoading = false;
      });
      print('Erro ao buscar tarefas não confirmadas: $e');
    }
  }

  Future<void> _acknowledgeTask(String taskId) async {
    setState(() {
      _isLoading = true; // Mostra loading enquanto confirma
    });
    try {
      final success = await TaskService.acknowledgeAssignedTask(taskId);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarefa confirmada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchUnconfirmedTasks(); // Recarrega a lista para remover a tarefa confirmada
        widget.onTaskAcknowledged?.call(); // Dispara o callback para o pai, se houver
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao confirmar tarefa. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao confirmar tarefa: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false; // Garante que o loading seja desativado em caso de erro
      });
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
        ),
      );
    } else if (_unconfirmedTasks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Nenhuma tarefa não confirmada.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    } else {
      return ListView.builder(
        itemCount: _unconfirmedTasks.length,
        itemBuilder: (context, index) {
          final task = _unconfirmedTasks[index];
          return Card(
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(
                task.title,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              subtitle: Text(
                'Projeto: ${task.projeto?.nome ?? 'N/A'}', // Exibe o nome do projeto e quem está atribuído
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              trailing: _isLoading // Desabilita o botão enquanto carrega
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : ElevatedButton(
                      onPressed: () => _acknowledgeTask(task.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Confirmar'),
                    ),
              onTap: () {
                // TODO: Navegar para detalhes da tarefa, se necessário
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Detalhes da tarefa: ${task.title}')),
                );
              },
            ),
          );
        },
      );
    }
  }
}