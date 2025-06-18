import 'package:flutter/material.dart';
import 'package:code/servicesMobile/kanban_service.dart' as kanban_models;
import 'package:code/common/constants/app_colors.dart';
import 'package:intl/intl.dart';

// Definindo os callbacks para o KanbanColumn
typedef OnTaskMovedCallback = Future<void> Function(
    String taskId, String newColumnId, int newOrder);
typedef OnEditTaskCallback = void Function(kanban_models.KanbanTaskItem task);
typedef OnReviewCodeCallback = Future<void> Function(
    kanban_models.KanbanTaskItem task);
typedef OnAddTaskCallback = void Function(String columnId);
// NOVO: Callback quando uma tarefa é solta NESTA coluna
typedef OnTaskDropCallback = void Function(
    kanban_models.KanbanTaskItem task, String newColumnId, int newOrder);

class KanbanColumn extends StatelessWidget {
  final kanban_models.KanbanColumn kanbanColumn;
  final OnTaskMovedCallback onTaskMoved;
  final OnEditTaskCallback? onEditTask;
  final OnReviewCodeCallback? onReviewCode;
  final OnAddTaskCallback? onAddTask;
  final OnTaskDropCallback
      onTaskDrop; // NOVO: Callback para quando uma tarefa é solta aqui
  final String currentUserId; // Adicionado para passar o ID do usuário logado

  const KanbanColumn({
    super.key,
    required this.kanbanColumn,
    required this.onTaskMoved,
    required this.onTaskDrop, // Deve ser fornecido
    this.onEditTask,
    this.onReviewCode,
    this.onAddTask,
    required this.currentUserId, // Deve ser fornecido
  });

  Color _getColumnColor(String statusMapping) {
    switch (statusMapping) {
      case 'pending': return Colors.redAccent.withOpacity(0.7); // AUMENTADO OPACIDADE
      case 'in_progress': return Colors.orangeAccent.withOpacity(0.7); // AUMENTADO OPACIDADE
      case 'done': return Colors.greenAccent.withOpacity(0.7); // AUMENTADO OPACIDADE
      case 'cancelled': return Colors.grey.withOpacity(0.7); // AUMENTADO OPACIDADE
      default: return Colors.blueGrey.withOpacity(0.7); // AUMENTADO OPACIDADE
    }
  }


  Color _getTaskStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'done':
        return AppColors.success;
      case 'cancelled':
        return Colors.grey;
      case 'approved':
        return Colors.purple;
      default:
        return Colors.black;
    }
  }

  String _getTaskStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'in_progress':
        return 'Em Progresso';
      case 'done':
        return 'Concluída';
      case 'cancelled':
        return 'Cancelada';
      case 'approved':
        return 'Aprovada';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final columnTitle = kanbanColumn.name;
    final columnColor = _getColumnColor(kanbanColumn.statusMapping);
    final List<kanban_models.KanbanTaskItem> tasksInColumn = kanbanColumn.tasks;

    return Expanded(
      child: DragTarget<kanban_models.KanbanTaskItem>(
        // KanbanColumn agora é um DragTarget
        onAcceptWithDetails:
            (DragTargetDetails<kanban_models.KanbanTaskItem> details) {
          // Quando uma tarefa é solta NESTA coluna
          final droppedTask = details.data;
          // Determine a nova ordem (simples: coloca no final da coluna por enquanto)
          // Uma implementação mais avançada usaria a posição do drop.
          final newOrder = kanbanColumn.tasks.length; // Coloca no final
          onTaskDrop(droppedTask, kanbanColumn.id, newOrder);
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: candidateData.isNotEmpty
                    ? Colors.blueAccent
                    : Colors.transparent, // Feedback visual ao arrastar sobre
                width: 2,
              ),
            ),
            child: Column(
              children: [
                // Cabeçalho da Coluna
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: columnColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      columnTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Lista de Tarefas (agora itens são Draggable)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: tasksInColumn.length,
                    itemBuilder: (context, index) {
                      final task = tasksInColumn[index];
                      final isDone =
                          task.status == 'done' || task.status == 'approved';
                      final isAssignedToCurrentUser = task.assignedToUsers
                          .any((u) => u.id == currentUserId);
                      // TODO: Lógica para verificar se o usuário é Scrum Master do projeto.
                      final bool isScrumMaster = false; // Placeholder

                      // Cada Card de Tarefa é um LongPressDraggable
                      return LongPressDraggable<kanban_models.KanbanTaskItem>(
                        data: task, // Os dados que serão arrastados
                        feedback: Material(
                          // O widget que é exibido durante o arrastar
                          elevation: 4.0,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            width:
                                200, // Largura do feedback (ajuste conforme necessário)
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).cardColor.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              task.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        childWhenDragging: Card(
                          // O que é mostrado no lugar do widget original enquanto ele é arrastado
                          color: Colors.grey.withOpacity(0.5),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child:
                              const SizedBox(height: 80), // Altura placeholder
                        ),
                        onDragCompleted: () {
                          // Chamado quando o draggable é aceito por um DragTarget
                          // A lógica de atualização é feita no onAcceptWithDetails do DragTarget
                        },
                        child: Card(
                          // O widget original da tarefa
                          key: ValueKey(task.id),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(task.description ?? '',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(
                                  'Vence: ${task.deadline != null ? DateFormat('dd/MM').format(task.deadline!) : 'N/A'}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  'Resp: ${task.assignedToUsers.map((u) => u.nome).join(', ')}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                              _getTaskStatusColor(task.status),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _getTaskStatusText(task.status),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (isDone &&
                                          (isScrumMaster /* || isProductOwner */))
                                        IconButton(
                                          icon: const Icon(Icons.rate_review,
                                              color: AppColors.primary),
                                          onPressed: onReviewCode != null
                                              ? () => onReviewCode!(task)
                                              : null,
                                          tooltip: 'Avaliar Código',
                                        ),
                                      // PopupMenuButton para mover a tarefa via menu
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert),
                                        onSelected: (String value) {
                                          if (value.startsWith('move_to_')) {
                                            final newColumnId = value
                                                .substring('move_to_'.length);
                                            // A ordem 9999 coloca no final, mas se você tiver DnD, esta opção pode ser secundária
                                            onTaskMoved(
                                                task.id, newColumnId, 9999);
                                          }
                                        },
                                        itemBuilder: (BuildContext context) {
                                          final List<PopupMenuEntry<String>>
                                              items = [];
                                          // Esta lista de colunas DEVE ser passada do KanbanProjectView
                                          // via um novo parâmetro em KanbanColumn, ex: `List<kanban_models.KanbanColumn> allColumns`
                                          // Por simplicidade, usando hardcoded para exemplo.
                                          final List<kanban_models.KanbanColumn>
                                              allAvailableColumns = [
                                            kanban_models.KanbanColumn(
                                                id: 'todo',
                                                name: 'A Fazer',
                                                order: 0,
                                                statusMapping: 'pending',
                                                tasks: const []),
                                            kanban_models.KanbanColumn(
                                                id: 'in-progress',
                                                name: 'Em Andamento',
                                                order: 1,
                                                statusMapping: 'in_progress',
                                                tasks: const []),
                                            kanban_models.KanbanColumn(
                                                id: 'done',
                                                name: 'Concluído',
                                                order: 2,
                                                statusMapping: 'done',
                                                tasks: const []),
                                            kanban_models.KanbanColumn(
                                                id: 'cancelled',
                                                name: 'Cancelado',
                                                order: 3,
                                                statusMapping: 'cancelled',
                                                tasks: const []),
                                            // Inclua aqui outras colunas customizadas que o KanbanProjectView passar
                                          ];

                                          for (var col in allAvailableColumns) {
                                            if (col.id != kanbanColumn.id) {
                                              items.add(
                                                PopupMenuItem<String>(
                                                  value: 'move_to_${col.id}',
                                                  child: Text(
                                                      'Mover para ${col.name}'),
                                                ),
                                              );
                                            }
                                          }
                                          return items;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Botão Adicionar Tarefa à Coluna
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: onAddTask != null
                      ? () => onAddTask!(kanbanColumn.id)
                      : null,
                  tooltip: 'Adicionar tarefa nesta coluna',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
