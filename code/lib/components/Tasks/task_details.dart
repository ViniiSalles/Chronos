import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TaskDetails extends StatefulWidget {
  // Objeto da tarefa principal recebido pela tela anterior
  final Map<String, dynamic> task; 

  const TaskDetails({super.key, required this.task});

  @override
  State<TaskDetails> createState() => _TaskDetailsState();
}

class _TaskDetailsState extends State<TaskDetails> {
  // Lista para armazenar as tarefas que são pré-requisitos desta
  List<Map<String, dynamic>> tarefasRelacionadas = [];
  
  // Variável para indicar se os dados ainda estão sendo carregados
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Inicia a busca dos dados assim que a tela é construída
    _fetchDependentTasks();
  }

  /// Busca os detalhes das tarefas que são pré-requisitos (tarefasAnteriores).
  Future<void> _fetchDependentTasks() async {
    // Verifica se o widget ainda está "montado" (na árvore de widgets)
    // para evitar erros se o usuário fechar a tela antes da busca terminar.
    if (!mounted) return;

    // Acessa a lista de IDs das tarefas anteriores a partir do widget.task
    final List<dynamic> tarefasAnterioresIds = widget.task['tarefasAnteriores'] ?? [];

    if (tarefasAnterioresIds.isNotEmpty) {
      try {
        var tasksArray = <Map<String, dynamic>>[];

        // Itera sobre cada ID para buscar os detalhes da tarefa correspondente
        for (var taskId in tarefasAnterioresIds) {
          final url = Uri.parse('http://chronos-production-f584.up.railway.app/tasks/$taskId');
          final response = await http.get(url);

          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            tasksArray.add({
              "titulo": decoded["titulo"],
              "data": decoded['dataLimite'],
              "status": decoded['status'] == "pending" ? "Pendente" : 'Em andamento'
            });
          } else {
             // Opcional: Tratar erros caso uma tarefa específica não seja encontrada
            print('Erro ao buscar tarefa $taskId: Status ${response.statusCode}');
          }
        }
        
        // Atualiza o estado com as tarefas encontradas
        if (mounted) {
          setState(() {
            tarefasRelacionadas = tasksArray;
            _isLoading = false;
          });
        }

      } catch (e) {
        // Trata erros de conexão ou outros problemas
        print('Ocorreu um erro ao buscar tarefas: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
       // Se não houver tarefas anteriores, apenas para de carregar
       if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: 1300,
        height: 400,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Título e Complexidade da Tarefa
                Flexible(
                  child: Text(
                    "${widget.task["titulo"]} - ${widget.task["complexidade"]}",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Status da Tarefa
                // Text(
                //   widget.task['status'],
                //   style: const TextStyle(
                //     fontSize: 16,
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coluna da Descrição
                  Expanded(
                    flex: 2, // Ocupa 2/3 do espaço
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Descrição:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SizedBox(
                            width: 800,
                            height: 350,
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 250, 250, 250),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    widget.task['descricao'],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Coluna das Tarefas Dependentes
                  Expanded(
                    flex: 1, // Ocupa 1/3 do espaço
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Tarefas anteriores:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 250, 250, 250),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: _buildDependentTasksList(),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      // Botão para fechar o diálogo
      actions: <Widget>[
        TextButton(
          child: const Text('Fechar', style: TextStyle(fontSize: 16)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  /// Constrói o widget da lista de tarefas, tratando os estados de carregamento.
  Widget _buildDependentTasksList() {
    if (_isLoading) {
      // Mostra um indicador de progresso enquanto os dados são buscados
      return const Center(child: CircularProgressIndicator());
    }

    if (tarefasRelacionadas.isEmpty) {
      // Mostra a mensagem se nenhuma tarefa for encontrada
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Nenhuma tarefa anterior encontrada.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // Mostra a lista de tarefas se houver dados
    return Scrollbar(
      thumbVisibility: true,
      child: ListView.builder(
        itemCount: tarefasRelacionadas.length,
        itemBuilder: (context, index) {
          final task = tarefasRelacionadas[index];
          return ListTile(
            title: Text(
              "${task['titulo']} - ${task['status']}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              // Formata a data para dd/mm/yyyy
              "${DateTime.parse(task['data']).day.toString().padLeft(2, '0')}/${DateTime.parse(task['data']).month.toString().padLeft(2, '0')}/${DateTime.parse(task['data']).year}",
              style: const TextStyle(fontSize: 14),
            ),
          );
        },
      ),
    );
  }
}