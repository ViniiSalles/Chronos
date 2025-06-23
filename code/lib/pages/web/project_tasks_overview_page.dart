import 'package:flutter/material.dart';
import 'package:code/common/constants/app_colors.dart';
import 'package:code/services/task_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProjectTasksOverviewPage extends StatefulWidget {
  final String projectId;
  final String projectName;
  final DateTime projectStartDate; // Pode ser útil para contexto

  const ProjectTasksOverviewPage({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.projectStartDate,
  });

  @override
  State<ProjectTasksOverviewPage> createState() =>
      _ProjectTasksOverviewPageState();
}

class _ProjectTasksOverviewPageState extends State<ProjectTasksOverviewPage> {
  List<Task> _projectTasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProjectTasks();
  }

  Future<void> _fetchProjectTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<Task> allTasks = await TaskService.getTasks();

      if (!mounted) return;

      _projectTasks = allTasks.where((task) {
        final bool belongsToProject = task.projectId == widget.projectId;
        final bool isPending = task.status == TaskStatus.pending;
        final bool isAcknowledged = task.recebidaPeloAtribuido ?? false;

        // Tarefas pendentes E tarefas confirmadas
        return belongsToProject && (isPending || isAcknowledged);
      }).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao carregar tarefas do projeto: ${e.toString()}';
        _isLoading = false;
      });
      print('Erro ao buscar tarefas do projeto ${widget.projectName}: $e');
    }
  }

  // Função para completar a tarefa
  Future<void> _completeTask(Task task) async {
    // Obtenha o ID do usuário logado
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não logado.')),
      );
      return;
    }

    // Abrir um diálogo para coletar tempo_gasto_horas e code
    final Map<String, String?>? result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) =>
          _CompleteTaskDialog(), // Componente de diálogo para input
    );

    if (result == null) {
      // Usuário cancelou o diálogo
      return;
    }

    final double? tempoGastoHoras =
        double.tryParse(result['tempo_gasto_horas'] ?? '');
    final String? code = result['code'];

    if (tempoGastoHoras == null || tempoGastoHoras <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tempo gasto inválido.')),
      );
      return;
    }
    if (code == null || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código da tarefa é obrigatório.')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Ativa o loading
    });
    try {
      final success = await TaskService.completeTask(
          task.id, currentUserId, tempoGastoHoras, code);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarefa concluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchProjectTasks(); // Recarrega a lista para refletir a mudança de status
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao concluir tarefa. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao concluir tarefa: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false; // Desativa o loading em caso de erro
      });
    }
  }

  // A função _sendTaskMessage foi removida, pois o botão foi substituído.

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Tarefas do Projeto: ${widget.projectName}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                )
              : _projectTasks.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma tarefa encontrada para o projeto ${widget.projectName} com status pendente ou confirmada.',
                        style: const TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchProjectTasks,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _projectTasks.length,
                        itemBuilder: (context, index) {
                          final task = _projectTasks[index];
                          // Verifique se o usuário atual está atribuído à tarefa
                          final bool isAssignedToCurrentUser =
                              task.assignedTo == currentUserId;
                          final bool isAcknowledged =
                              task.recebidaPeloAtribuido ?? false;
                          final bool isPending =
                              task.status == TaskStatus.pending;
                          // Uma tarefa está concluída ou aprovada se o status for 'completed' ou 'approved'
                          final bool isCompletedOrApproved =
                              task.status == 'completed';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    task.description,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          size: 16,
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Vence: ${task.deadline != null ? DateFormat('dd/MM/yyyy').format(task.deadline!) : 'N/A'}',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.person,
                                          size: 16,
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      // Exibe o status da tarefa
                                      const SizedBox(width: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(task.status),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _getStatusText(task.status),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Botão "Concluir Tarefa"
                                  // Visível se o usuário logado for o atribuído E a tarefa não estiver concluída/aprovada
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _completeTask(task),
                                        icon: const Icon(
                                            Icons.check_circle_outline,
                                            color: Colors.white),
                                        label: const Text('Concluir Tarefa',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.success,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  // Métodos auxiliares para exibir status da tarefa (similar ao ProjectListPage)
  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return AppColors.success;
      case TaskStatus.cancelled:
        return Colors.grey;
      // Se você tiver um status 'approved' no enum TaskStatus, adicione-o aqui
      // case TaskStatus.approved: return Colors.purple;
      default:
        return Colors.black; // Fallback
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pendente';
      case TaskStatus.inProgress:
        return 'Em Progresso';
      case TaskStatus.completed:
        return 'Concluída';
      case TaskStatus.cancelled:
        return 'Cancelada';
      // Se você tiver um status 'approved' no enum TaskStatus, adicione-o aqui
      // case TaskStatus.approved: return 'Aprovada';
      default:
        return 'Desconhecido'; // Fallback
    }
  }
}

// Componente de diálogo para coletar input de tempo e código
class _CompleteTaskDialog extends StatefulWidget {
  @override
  __CompleteTaskDialogState createState() => __CompleteTaskDialogState();
}

class __CompleteTaskDialogState extends State<_CompleteTaskDialog> {
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _timeController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Completar Tarefa'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _timeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tempo Gasto (horas)',
                hintText: 'Ex: 8.5',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe o tempo gasto.';
                }
                if (double.tryParse(value) == null) {
                  return 'Valor inválido. Use números.';
                }
                if (double.parse(value) <= 0) {
                  return 'O tempo deve ser maior que zero.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Código da Tarefa',
                hintText: 'Ex: feature-abc-123',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe o código da tarefa.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(null), // Retorna null se cancelado
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'tempo_gasto_horas': _timeController.text,
                'code': _codeController.text,
              });
            }
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
