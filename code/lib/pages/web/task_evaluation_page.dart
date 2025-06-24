import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../common/constants/app_colors.dart';
import '../../services/evaluation_service.dart';

class TaskEvaluationPage extends StatefulWidget {
  final String projectId;
  final String projectName; // Adicionado como um campo da classe

  const TaskEvaluationPage({
    super.key,
    required this.projectId,
    required this.projectName, // Agora é um campo obrigatório
  });

  @override
  State<TaskEvaluationPage> createState() => _TaskEvaluationPageState();
}

class _TaskEvaluationPageState extends State<TaskEvaluationPage> {
  late Future<List<EvaluatableTask>> _tasksFuture;
  final EvaluationService _evaluationService = EvaluationService();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    setState(() {
      _tasksFuture =
          _evaluationService.getCompletedTasks(widget.projectId, _refreshTasks);
    });
  }

  void _refreshTasks() {
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // AppBar adicionada para contexto e navegação
      appBar: AppBar(
        title: Text('Avaliação de Entregas - ${widget.projectName}',
            style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Textos de cabeçalho podem ser removidos, já que agora estão na AppBar
            // Se preferir, pode mantê-los.
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<EvaluatableTask>>(
                future: _tasksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text(
                            'Erro ao carregar tarefas: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('Nenhuma tarefa concluída para avaliar.'));
                  }

                  final tasks = snapshot.data!;
                  return ListView.separated(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return TaskEvaluationTile(task: tasks[index]);
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// O widget TaskEvaluationTile permanece o mesmo do seu código
class TaskEvaluationTile extends StatefulWidget {
  final EvaluatableTask task;

  const TaskEvaluationTile({super.key, required this.task});

  @override
  State<TaskEvaluationTile> createState() => _TaskEvaluationTileState();
}

class _TaskEvaluationTileState extends State<TaskEvaluationTile> {
  final TextEditingController _commentController = TextEditingController();
  double _currentRating = 0;
  bool _isSaving = false;

  final EvaluationService _evaluationService = EvaluationService();

  @override
  void initState() {
    super.initState();
    if (widget.task.avaliacao != null) {
      _currentRating = widget.task.avaliacao!.nota;
      _commentController.text = widget.task.avaliacao!.comentario;
    }
  }

  Future<void> _submitEvaluation() async {
    if (_currentRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, selecione uma nota.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    bool success = await _evaluationService.submitEvaluation(
      taskId: widget.task.id,
      rating: _currentRating,
      comment: _commentController.text,
    );

    setState(() {
      _isSaving = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Avaliação salva com sucesso!'),
            backgroundColor: Colors.green),
      );
      widget.task.onEvaluationSubmitted();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erro ao salvar avaliação.'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEvaluated = widget.task.avaliacao != null;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface, // Melhor contraste
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Responsável: ${widget.task.usuarioNome}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                RatingBar.builder(
                  initialRating: _currentRating,
                  minRating: 1,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: AppColors.primary),
                  onRatingUpdate: (rating) {
                    if (!isEvaluated) {
                      setState(() {
                        _currentRating = rating;
                      });
                    }
                  },
                  ignoreGestures: isEvaluated,
                  glow: false,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _commentController,
                    readOnly: isEvaluated,
                    decoration: InputDecoration(
                      hintText: isEvaluated
                          ? (_commentController.text.isNotEmpty
                              ? _commentController.text
                              : 'Sem comentário')
                          : 'Adicionar comentário...',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (!isEvaluated)
                  _isSaving
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _submitEvaluation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Salvar'),
                        ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
