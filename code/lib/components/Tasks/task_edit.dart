import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:code/common/constants/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TaskEdit extends StatefulWidget {
  final Map<String, dynamic> task;
  final String idProjeto;
  final List<Map<String, dynamic>> tarefasExistentes;
  final List<String> prioridades;
  final List<String> niveis;

  const TaskEdit({
    super.key,
    required this.task,
    required this.tarefasExistentes,
    required this.prioridades,
    required this.niveis,
    required this.idProjeto,
  });

  @override
  State<TaskEdit> createState() => _TaskEditState();
}

class _TaskEditState extends State<TaskEdit> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final List<String> _tarefasDoProjeto = [];
  List<String> _selecionadas = [];
  String? _prioridadeSelecionada;
  String? _nivelSelecionado;
  String? _responsavelSelecionado;

  final List<Map<String, dynamic>> dependentTasks = [];

  final List<Map<String, dynamic>> taskLevels = [
    {"label": "A", "value": "A"},
    {"label": "B", "value": "B"},
    {"label": "C", "value": "C"},
    {"label": "D", "value": "D"},
  ];

  List<String> prioridade = ['alta', 'Média', 'Baixa'];
  final List<Map<String, dynamic>> _responsaveis = [];
  // 1. Crie TextEditingControllers para todos os campos editáveis:
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();

  @override
  void initState() {
    super.initState();

    print("------------------tasksUsuarios");
    print(widget.task);

    fetchUsers();
    setTasksInArray();

    _tituloController.text = widget.task["titulo"] ?? '';
    _descricaoController.text = widget.task["descricao"] ?? '';
    _dataController.text = widget.task["dataLimite"] != null
        ? DateFormat('dd/MM/yyyy')
            .format(DateTime.parse(widget.task["dataLimite"]))
        : '';
    _responsavelSelecionado = (widget.task["atribuicoes"] != null &&
            widget.task["atribuicoes"].isNotEmpty)
        ? widget.task["atribuicoes"][0].toString()
        : null;
    _prioridadeSelecionada = widget.task["prioridade"];
    _nivelSelecionado = widget.task["complexidade"];
    _selecionadas = widget.task["tarefasAnteriores"] != null
        ? List<String>.from(widget.task["tarefasAnteriores"])
        : [];
  }

  void fetchUsers() async {
    final url = Uri.parse(
        'https://chronos-production-f584.up.railway.app/project/${widget.idProjeto}');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      setUsersArray(response.body);
    } else {
      print('Erro ao buscar dados: ${response.statusCode}');
    }
  }

  void setUsersArray(String array) {
    final decoded = jsonDecode(array);
    final List<dynamic> data = decoded['users'];
    final List<Map<String, dynamic>> users = [];

    for (var item in data) {
      // if(item['papel'] == "usuario"){
      final userInfo = {"id": item['id'], "name": item['nome']};
      users.add(userInfo);
      // }
    }

    setState(() {
      _responsaveis.addAll(users);
    });
  }

  void setTask() async {
    final url = Uri.parse(
        'https://chronos-production-f584.up.railway.app/tasks/${widget.task["_id"]}');

    print(_selecionadas);

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "titulo": _tituloController.text,
        "descricao": _descricaoController.text,
        "prioridade": _prioridadeSelecionada,
        "complexidade": _nivelSelecionado,
        "dataInicio": "2025-05-01T09:00:00.000Z",
        "dataLimite": _dataController.text.isNotEmpty
            ? DateFormat('dd/MM/yyyy')
                .parse(_dataController.text)
                .toIso8601String()
            : null,
        "atribuicoes": [_responsavelSelecionado],
        "tarefasAnteriores": _selecionadas
      }),
    );

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sucesso'),
        content: const Text('Cadastro alterado com sucesso!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o alerta
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (response.statusCode == 201) {
      print('Resposta da requisição: ${response.body}');
    } else {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erro'),
            content: Text('Falha ao salvar a task: ${response.body}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void setTasksInArray() {
    var taskArray = [];

    for (var task in widget.tarefasExistentes) {
      if (task["id"] != widget.task['id']) {
        var taskData = {
          "label": task["titulo"],
          "value": task["id"],
        };

        taskArray.add(taskData);
      }
    }

    setState(() {
      // If you want to add new tasks to tarefasExistentes, add as Map<String, dynamic>
      _tarefasDoProjeto.addAll(taskArray.map((e) => e["label"] as String));
    });
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itens = widget.tarefasExistentes
        .map((task) => MultiSelectItem(task['_id'], task['titulo']))
        .toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Editar Task",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 600,
        height: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TÍTULO

                // 3. No campo TÍTULO:
                SizedBox(
                  width: 500,
                  child: TextFormField(
                    controller: _tituloController,
                    decoration: _inputDecoration('Título da task').copyWith(
                      fillColor: Colors.grey[100],
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Informe o título'
                        : null,
                  ),
                ),

                const SizedBox(height: 16),

                // 4. DATA E TASKS DEPENDENTES
                Row(
                  children: [
                    SizedBox(
                      width: 240,
                      child: GestureDetector(
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: widget.task["dataLimite"] != null
                                ? DateTime.parse(widget.task["dataLimite"])
                                : DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _dataController.text =
                                  DateFormat('dd/MM/yyyy').format(picked);
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _dataController,
                            readOnly: true,
                            decoration: _inputDecoration(
                              'Data',
                              icon: Icons.calendar_today,
                            ).copyWith(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.blue, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              fillColor: Colors.grey[100],
                              filled: true,
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Informe a data'
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 240,
                      child: MultiSelectDialogField(
                        items: widget.tarefasExistentes
                            .where((task) => task["_id"] != widget.task['_id'])
                            .map((task) =>
                                MultiSelectItem(task['_id'], task['titulo']))
                            .toList(),
                        title: const Text("Tasks dependentes"),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        buttonText: const Text("Selecionar dependências"),
                        buttonIcon: const Icon(Icons.arrow_drop_down),
                        initialValue: _selecionadas,
                        onConfirm: (values) {
                          setState(() {
                            _selecionadas = values.cast<String>();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. DESCRIÇÃO
                SizedBox(
                  width: 500,
                  child: TextFormField(
                    controller: _descricaoController,
                    decoration: _inputDecoration('Descrição').copyWith(
                      fillColor: Colors.grey[100],
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    maxLines: 4,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Informe a descrição'
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                /// PRIORIDADE, NÍVEL, RESPONSÁVEL
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: DropdownButtonFormField<String>(
                        value: _nivelSelecionado,
                        decoration: _inputDecoration('Nível').copyWith(
                          fillColor: Colors.grey[100],
                          filled: true,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.blue, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: taskLevels
                            .map((p) => DropdownMenuItem<String>(
                                value: p['value'], child: Text(p['label'])))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _nivelSelecionado = value),
                        validator: (value) =>
                            value == null ? 'Selecione o nível' : null,
                      ),
                    ),
                    const SizedBox(width: 25),
                    SizedBox(
                      width: 150,
                      child: DropdownButtonFormField<String>(
                        value: prioridade.contains(widget.task["prioridade"])
                            ? widget.task["prioridade"]
                            : null,
                        decoration: _inputDecoration('Prioridade').copyWith(
                          fillColor: Colors.grey[100],
                          filled: true,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.blue, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: prioridade
                            .map((n) =>
                                DropdownMenuItem(value: n, child: Text(n)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _prioridadeSelecionada = value),
                        validator: (value) =>
                            value == null ? 'Selecione a prioridade' : null,
                      ),
                    ),
                    const SizedBox(width: 25),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        // value:  widget.task["atribuicoes"][0],
                        decoration: _inputDecoration('Responsável').copyWith(
                          fillColor: Colors.grey[100],
                          filled: true,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.blue, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: _responsavelSelecionado,
                        items: _responsaveis
                            .map((r) => DropdownMenuItem<String>(
                                  value: r['id'],
                                  child: Text(r['name']),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _responsavelSelecionado = value),
                        validator: (value) =>
                            value == null ? 'Selecione o responsável' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                /// BOTÕES
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          setTask();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Salvar',
                        style: TextStyle(color: AppColors.surface),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
