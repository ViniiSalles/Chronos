import 'package:flutter/material.dart';

class TaskDetails extends StatefulWidget {
  final Map<String, dynamic> task; // Adicionado para receber o objeto da tarefa

  const TaskDetails({super.key, required this.task});

  @override
  State<TaskDetails> createState() => _TaskDetailsState();
}



class _TaskDetailsState extends State<TaskDetails> {
  final List<Map<String, dynamic>> taskOccurrences = [
    {"action": "Task Created", "date": DateTime(2023, 1, 15)},
    {"action": "Status Updated to In Progress", "date": DateTime(2023, 1, 20)},
    {"action": "Description Edited", "date": DateTime(2023, 1, 25)},
    {"action": "Status Updated to Completed", "date": DateTime(2023, 2, 5)},
  ];

  final List<Map<String, dynamic>> dependentTasks = [
    {"title": "Subtask 1", "status": "In Progress"},
    {"title": "Subtask 2", "status": "Not Started"},
    {"title": "Subtask 3", "status": "Completed"},
    {"title": "Subtask 3", "status": "Completed"},
    {"title": "Subtask 3", "status": "Completed"},
    {"title": "Subtask 3", "status": "Completed"},
    {"title": "Subtask 3", "status": "Completed"},
    {"title": "Subtask 3", "status": "Completed"},
  ];

  @override
  void initState() {
    super.initState();
    _onPageLoaded();
  }

  void _onPageLoaded() {
    print("oláaaaaaa");
    print(widget.task);
  }



  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: 1300,
        height: 600,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${widget.task["titulo"]} - ${widget.task["complexidade"]}",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.task['status'],
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Descrição:",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      width: 750,
                      height: 250,
                      padding: const EdgeInsets.all(16.0), // Define o padding
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(
                            255, 250, 250, 250), // Define o background
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Scrollbar(
                        thumbVisibility:
                            true, // Torna a barra de rolagem visível
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            widget.task['descricao'],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text("Histórico:",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )),
                    Container(
                      width: 450,
                      height: 150,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 250, 250, 250),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: ListView.builder(
                          itemCount: taskOccurrences.length,
                          itemBuilder: (context, index) {
                            final occurrence = taskOccurrences[index];
                            return ListTile(
                              title: Text(
                                occurrence['action'],
                                style: const TextStyle(fontSize: 16),
                              ),
                              subtitle: Text(
                                occurrence['date'].toString(),
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tasks dependentes:",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )),
                    Container(
                      width: 200,
                      height: 350,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 250, 250, 250),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: ListView.builder(
                          itemCount: dependentTasks.length,
                          itemBuilder: (context, index) {
                            final task = dependentTasks[index];
                            return ListTile(
                              title: Text(
                                task['title'],
                                style: const TextStyle(fontSize: 16),
                              ),
                              subtitle: Text(
                                task['status'].toString(),
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
