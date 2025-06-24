import 'package:flutter/material.dart';
import 'package:code/services/task_service.dart';

class TaskDeleteModal extends StatelessWidget {
  final String taskId;
  final String taskTitle;
  final VoidCallback onDelete;

  const TaskDeleteModal({
    super.key,
    required this.taskId,
    required this.taskTitle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Excluir Task',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Text(
        'Tem certeza que deseja excluir a task "$taskTitle"? Esta ação não pode ser desfeita.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            final success = await TaskService.deleteTask(taskId);
            if (success) {
              onDelete();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao excluir a task. Tente novamente.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('Excluir'),
        ),
      ],
    );
  }
} 