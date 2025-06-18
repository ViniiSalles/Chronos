import 'package:flutter/material.dart';
import 'package:code/components/Tasks/task_card.dart';
import 'package:code/components/Tasks/task_details.dart';
import 'package:code/servicesMobile/task_service.dart';

class ProjectTask extends StatefulWidget {
  final String projectName; // Nome do projeto
  final String projectId;
  final List<Map<String, dynamic>> tasks;
  final void Function(Map<String, dynamic> task)? fetchData; // Função opcional

  const ProjectTask({
    super.key,
    required this.projectName,
    required this.tasks,
    this.fetchData,
    required this.projectId,
  });

  @override
  State<ProjectTask> createState() => _ProjectTaskState();
}

class _ProjectTaskState extends State<ProjectTask> {
  void _handleTaskDelete() {
    if (widget.fetchData != null) {
      widget.fetchData!({});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 600, // Define uma altura fixa para o GridView
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // Define o número de colunas
          crossAxisSpacing: 16.0, // Espaçamento horizontal entre os cards
          mainAxisSpacing: 16.0, // Espaçamento vertical entre os cards
          childAspectRatio: 3 / 2, // Proporção largura/altura dos cards
        ),
        itemCount: widget.tasks.length,
        itemBuilder: (context, index) {
          final task = widget.tasks[index];
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => TaskDetails(task: task),
              );
            },
            child: TaskCard(
              task: Task.fromJson({
                ...task,
                // Ensure status is the correct enum or value expected by TaskCard
                'status': task['status'] ?? task['status'] ?? 'pending',
              }),
              isSmall: false,
              onStatusChanged: (status) async {
                final updatedTask = Task(
                  id: task['_id'],
                  title: task['titulo'],
                  description: task['descricao'],
                  completed: task['concluida'] ?? false,
                  deadline: task['dataLimite'] != null ? DateTime.parse(task['dataLimite']) : null,
                  status: status,
                  priority: task['prioridade'] ?? 'média',
                  assignedTo: task['atribuidoPara'],
                );
                final success = await TaskService.updateTask(updatedTask);
                if (success && widget.fetchData != null) {
                  widget.fetchData!({});
                }
              },
            ),
          );
        },
      ),
    );
  }
}
