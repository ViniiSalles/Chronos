import 'package:flutter/material.dart';
import 'package:code/components/mobile_layout.dart';
import 'package:code/components/Tasks/task_card.dart';
import 'package:code/servicesMobile/task_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskListMobilePage extends StatefulWidget {
  const TaskListMobilePage({super.key});

  @override
  State<TaskListMobilePage> createState() => _TaskListMobilePageState();
}

class _TaskListMobilePageState extends State<TaskListMobilePage> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Usuário não autenticado. Faça o login para ver suas tarefas.");
      }


      // Este método é o equivalente exato do 'getMyProjects' que já funciona.
      final tasks = await TaskService.findAssignedTasksForUser();

      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar tarefas: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _handleStatusChange(Task task, TaskStatus newStatus) async {
    try {
      final updatedTask = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        completed: newStatus == TaskStatus.completed,
        deadline: task.deadline,
        status: newStatus,
        priority: task.priority,
        assignedTo: task.assignedTo, complexidade: '',
      );

      final success = await TaskService.updateTask(updatedTask);
      if (success) {
        await _loadTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Falha ao atualizar status da tarefa');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteTask(Task task) async {
    try {
      final success = await TaskService.deleteTask(task.id);
      if (success) {
        await _loadTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tarefa excluída com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Falha ao excluir tarefa');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir tarefa: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Tarefa'),
        content: Text('Tem certeza que deseja excluir a tarefa "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleDeleteTask(task);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmall = MediaQuery.of(context).size.width < 400;

    return MobileLayout(
      title: 'Tarefas',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadTasks,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : _tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 64,
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text('Nenhuma tarefa encontrada', style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 8),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTasks,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
                          return TaskCard(
                            task: task,
                            isSmall: isSmall,
                            onStatusChanged: (newStatus) => _handleStatusChange(task, newStatus),
                          );
                        },
                      ),
                    ),
    );
  }
}
