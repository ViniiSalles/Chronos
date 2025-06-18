import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import necessário para DateFormat
import 'package:code/servicesMobile/task_service.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool isSmall;
  final Function(TaskStatus) onStatusChanged;

  const TaskCard({
    super.key,
    required this.task,
    required this.isSmall,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, Color> taskDifficultyColors = {
      "A": const Color(0xFFD32F2F),
      "B": const Color(0xFFF57C00),
      "C": const Color(0xFFFDD835),
      "D": const Color(0xFF66BB6A),
    };

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12.0),
              topRight: Radius.circular(12.0),
            ),
            child: Container(
              color: taskDifficultyColors[task.priority.toString()] ??
                  const Color(0xFFF57C00),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.title.length > 20
                            ? '${task.title.substring(0, 20)}...'
                            : task.title,
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    DropdownButton<TaskStatus>(
                      value: TaskStatus.values.contains(task.status)
                          ? task.status
                          : null, // Evita erro se task.status for inválido
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.white),
                      dropdownColor:
                          taskDifficultyColors[task.priority.toString()] ??
                              const Color(0xFFF57C00),
                      items: [
                        DropdownMenuItem(
                          value: TaskStatus.pending,
                          child: Text(
                            'Pendente',
                            style: TextStyle(
                              color: task.status == TaskStatus.pending
                                  ? Colors.orange
                                  : Colors.white,
                              fontWeight: task.status == TaskStatus.pending
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: TaskStatus.inProgress,
                          child: Text(
                            'Em Progresso',
                            style: TextStyle(
                              color: task.status == TaskStatus.inProgress
                                  ? Colors.blue
                                  : Colors.white,
                              fontWeight: task.status == TaskStatus.inProgress
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: TaskStatus.completed,
                          child: Text(
                            'Concluída',
                            style: TextStyle(
                              color: task.status == TaskStatus.completed
                                  ? Colors.green
                                  : Colors.white,
                              fontWeight: task.status == TaskStatus.completed
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: TaskStatus.cancelled,
                          child: Text(
                            'Cancelada',
                            style: TextStyle(
                              color: task.status == TaskStatus.cancelled
                                  ? Colors.red // Cor para destacar "Cancelada"
                                  : Colors.white,
                              fontWeight: task.status == TaskStatus.cancelled
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (TaskStatus? newStatus) {
                        if (newStatus != null) {
                          onStatusChanged(newStatus);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.description,
                  style: const TextStyle(fontSize: 14.0),
                ),
                const SizedBox(height: 8.0),
                if (task.deadline != null)
                  Text(
                    'Prazo: ${DateFormat('dd/MM/yyyy').format(task.deadline!)}',
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
