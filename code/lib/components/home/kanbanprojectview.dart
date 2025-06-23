import 'package:flutter/material.dart';
import 'package:code/common/constants/app_colors.dart';
import 'package:code/components/home/kanban_column.dart'; // Este é o widget visual KanbanColumn
import 'package:code/pages/web/burndown_chart_page.dart';
import 'package:code/pages/web/project_tasks_overview_page.dart';
import 'package:code/services/kanban_service.dart'
    as kanban_models; // Importa os modelos do Kanban com um prefixo
import 'package:code/services/project_service.dart';
import 'package:code/components/Tasks/task_registration_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:code/services/task_service.dart'; // Importe o TaskService para reviewTaskUser
import 'package:code/pages/web/task_evaluation_page.dart';

// Componente de diálogo para avaliação de código (mantido igual)
class CodeReviewDialog extends StatefulWidget {
  final String taskId;
  final String assignedUserId;
  final String taskTitle;
  final String reviewerUserId; // Adicionado para passar o ID do avaliador

  const CodeReviewDialog({
    super.key,
    required this.taskId,
    required this.assignedUserId,
    required this.taskTitle,
    required this.reviewerUserId, // Adicionado
  });

  @override
  _CodeReviewDialogState createState() => _CodeReviewDialogState();
}

class _CodeReviewDialogState extends State<CodeReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _gradeController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Avaliar Código'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tarefa: ${widget.taskTitle}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(labelText: 'Comentário'),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty
                    ? 'Insira um comentário.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gradeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nota (0-10)'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Insira uma nota.';
                  final grade = double.tryParse(value);
                  if (grade == null || grade < 0 || grade > 10) {
                    return 'A nota deve ser entre 0 e 10.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration:
                    const InputDecoration(labelText: 'Código (Opcional)'),
                maxLines: 5,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isSubmitting = true);
                    try {
                      final success = await TaskService.reviewTaskUser(
                          widget.taskId,
                          widget
                              .assignedUserId, // ID do usuário avaliado (executor)
                          _commentController.text,
                          double.parse(_gradeController.text),
                          _codeController.text.isEmpty
                              ? null
                              : _codeController.text,
                          widget.reviewerUserId // ID do avaliador
                          );
                      if (!mounted) return;
                      if (success != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Avaliação enviada com sucesso!')));
                        Navigator.of(context).pop(true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Falha ao enviar avaliação.')));
                        Navigator.of(context).pop(false);
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Erro na avaliação: ${e.toString()}')));
                      Navigator.of(context).pop(false);
                    } finally {
                      if (mounted) setState(() => _isSubmitting = false);
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Avaliar'),
        ),
      ],
    );
  }
}

class KanbanProjectView extends StatefulWidget {
  final String projectName;
  final String projectId;
  final DateTime projectStartDate;
  final VoidCallback onBack;

  const KanbanProjectView({
    super.key,
    required this.projectName,
    required this.projectId,
    required this.projectStartDate,
    required this.onBack,
  });

  @override
  State<KanbanProjectView> createState() => _KanbanProjectViewState();
}

class _KanbanProjectViewState extends State<KanbanProjectView> {
  kanban_models.KanbanBoard? _kanbanBoard;
  bool _isLoading = true;
  String? _errorMessage;
  String? _userRole; // Adicionado para armazenar o papel do usuário no projeto
  bool _isProjectManager =
      false; // Variável para verificar se é gerente do projeto

  @override
  void initState() {
    super.initState();
    _fetchKanbanBoard();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() {
    return Future.sync(() async {
      if (widget.projectId.isNotEmpty) {
        final role =
            await ProjectService().getMyRoleInProject(widget.projectId);
        if (mounted) {
          setState(() {
            _userRole = role;
            if (_userRole != null) {
              // Verifica se o usuário é gerente do projeto ou Scrum Master
              _isProjectManager =
                  _userRole == 'Scrum Master' || 'admin' == _userRole;
            }
          });
        }
      }
      setState(() {
        _isLoading = false;
      });
    });
  }

  // Navega para a página de avaliação
  void _navigateToEvaluationPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskEvaluationPage(
          projectId: widget.projectId,
          projectName: widget.projectName,
        ),
      ),
    );
  }

  Future<void> _fetchKanbanBoard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      kanban_models.KanbanBoard? fetchedBoard =
          await kanban_models.KanbanService.getKanbanBoard(widget.projectId);
      if (!mounted) return;

      if (fetchedBoard == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Quadro Kanban não encontrado. Tentando criar...')),
        );
        fetchedBoard = await kanban_models.KanbanService.createKanbanBoard(
            widget.projectId);
        if (!mounted) return;
        if (fetchedBoard == null) {
          setState(() {
            _errorMessage =
                'Falha ao criar quadro Kanban. Verifique suas permissões.';
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _kanbanBoard = fetchedBoard;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao carregar/criar quadro Kanban: ${e.toString()}';
        _isLoading = false;
      });
      print('Erro ao buscar/criar quadro Kanban: $e');
    }
  }

  // Função para mover uma tarefa (chama o serviço backend)
  // Recebe a tarefa arrastada, a nova coluna e a nova ordem.
  Future<void> _onTaskMoved(kanban_models.KanbanTaskItem droppedTask,
      String newColumnId, int newOrder) async {
    try {
      // O KanbanService.moveKanbanTask espera taskId, newColumnId, newOrder
      await kanban_models.KanbanService.moveKanbanTask(
          droppedTask.id, newColumnId, newOrder);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarefa movida com sucesso!')),
      );
      _fetchKanbanBoard(); // Recarrega o quadro após a movimentação
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao mover tarefa: ${e.toString()}')),
      );
    }
  }

  // Função para abrir o formulário de adição de tarefa para uma coluna específica
  void _onAddTask(String columnId) async {
    final Project? currentProject =
        await ProjectService.getProjectById(widget.projectId);
    if (!mounted) return;

    if (currentProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Erro ao carregar dados do projeto para adicionar tarefa.')),
      );
      return;
    }

    // A lista `currentProject.tasks` pode conter `ObjectId`s se não estiver populada.
    // Você precisa de uma lista de Map<String, dynamic> com 'id' e 'name' para o MultiSelect.
    // Se Project.tasks for List<String> (IDs de ObjectId), você precisaria buscar detalhes de cada task
    // ou modificar o backend para popular Project.tasks com um formato que o TaskFormDialog espera.
    // Por simplicidade, vou usar a estrutura antiga e assumir que ela ainda funciona para os Map<String, dynamic>.
    // Se o backend mudou para apenas IDs em Project.tasks, isso precisaria de um serviço TaskService.getTasksByIds
    // e mapeamento de volta para o formato de Map.
    final List<Map<String, dynamic>> tarefasExistentesFormatadas =
        currentProject.tasks.map((taskItem) {
      // taskItem pode ser String (ObjectId) ou Map<String,dynamic> (subdocumento)
      // Baseado na sua última estrutura de Project, tasks é List<String> (IDs), então precisamos de detalhes.
      // Vou usar uma suposição para evitar erro, mas o ideal seria um populate no backend para Project.tasks
      // ou um TaskService.getTasksByIds no frontend.
      // Por agora, se for um Map (subdocumento antigo), pegamos, se for String (ObjectId novo), deixamos "N/A"
      return {"id": taskItem['id'], "name": taskItem['titulo']};
    }).toList();

    final List<Map<String, dynamic>> responsaveisFormatados =
        currentProject.users.map((userMap) {
      // users em Project pode ser Types.ObjectId[] no backend agora, e não Map<String, dynamic>
      // Se users for ObjectId[], currentProject.users não é Map<String, dynamic>
      // Assumindo que currentProject.users é populado ou que a estrutura antiga é mantida.
      return {"id": userMap['id'], "name": userMap['nome']};
    }).toList();

    showDialog(
      context: context,
      builder: (context) => TaskFormDialog(
        id: widget.projectId,
        tarefasExistentes: tarefasExistentesFormatadas,
        prioridades: const ['Alta', 'Média', 'Baixa'],
        niveis: const ['A', 'B', 'C', 'D'],
        responsaveis: responsaveisFormatados,
      ),
    ).then((_) {
      _fetchKanbanBoard();
    });
  }

  // Função para abrir o diálogo de avaliação de código
  Future<void> _onReviewCode(kanban_models.KanbanTaskItem task) async {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Usuário avaliador não logado.')));
      return;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CodeReviewDialog(
        taskId: task.id,
        assignedUserId: task.assignedToUsers.isNotEmpty
            ? task.assignedToUsers.first.id
            : '',
        taskTitle: task.title,
        reviewerUserId: currentUserId, // Passa o ID do avaliador
      ),
    );
    if (result == true) {
      _fetchKanbanBoard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.projectName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: widget.onBack,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart, color: AppColors.textPrimary),
            tooltip: 'Ver Gráfico Burndown',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BurndownChartPage(
                    projectId: widget.projectId,
                    queryStartDate: widget.projectStartDate,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.list_alt, color: AppColors.textPrimary),
            tooltip: 'Ver Todas as Tarefas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectTasksOverviewPage(
                    projectId: widget.projectId,
                    projectName: widget.projectName,
                    projectStartDate: widget.projectStartDate,
                  ),
                ),
              );
            },
          ),
          if (_isProjectManager) // Exibe o botão apenas se for gerente do projeto
            IconButton(
              icon:
                  const Icon(Icons.check_circle, color: AppColors.textPrimary),
              tooltip: 'Avaliar Entregas',
              onPressed: _navigateToEvaluationPage,
            ),
        ],
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
              : _kanbanBoard == null || _kanbanBoard!.columns.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Nenhum quadro Kanban encontrado ou colunas vazias.',
                            style: TextStyle(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _fetchKanbanBoard,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Recarregar / Criar Quadro'),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _kanbanBoard!.columns.map((column) {
                        return KanbanColumn(
                          kanbanColumn: column,
                          onTaskMoved: (taskId, newColumnId, newOrder) =>
                              _onTaskMoved(
                                  _kanbanBoard!.columns
                                      .expand((c) => c.tasks)
                                      .firstWhere((t) =>
                                          t.id ==
                                          taskId), // Encontra a tarefa completa
                                  newColumnId,
                                  newOrder), // Passa o objeto completo
                          onAddTask: _onAddTask,
                          onReviewCode: _onReviewCode,
                          onTaskDrop: (kanban_models.KanbanTaskItem task,
                              String newColumnId, int newOrder) {},
                          currentUserId: '',
                        );
                      }).toList(),
                    ),
    );
  }
}
