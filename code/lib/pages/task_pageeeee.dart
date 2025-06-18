import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();

  final List<String> _tasks = ['Task 1', 'Task 2', 'Task 3'];
  List<MultiSelectItem<String>> _itens = []; // Inicializa vazia

  final List<String> _prioridade = ['Alta', 'Média', 'Baixa'];
  final List<String> _nivel = ['A', 'B', 'C', 'D'];
  final List<String> _responsaveis = ['Evandro', 'Cleberson', 'Berzerk'];

  @override
  void initState() {
    super.initState();
    _itens = _tasks.map((task) => MultiSelectItem<String>(task, task)).toList();
  }

  List<String> _selecionadas = [];
  String? _prioridadeSelecionada;
  String? _nivelSelecionado;
  String? _responsavelSelecionado;

  void _mostrarModalDeCadastro(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Permite que o modal se ajuste ao conteúdo, incluindo o teclado
      builder: (BuildContext context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context)
                .viewInsets
                .bottom, // Evita que o teclado cubra os campos
          ),
          child: Container(
            child: Column(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration:
                            InputDecoration(labelText: 'Titulo da task'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o titulo da task';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          labelText: 'Data de limite de entrega',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true, // ← impede digitação manual
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                          );

                          if (pickedDate != null) {
                            String formattedDate = DateFormat(
                              'dd/MM/yyyy',
                            ).format(pickedDate);
                            setState(() {
                              _dateController.text = formattedDate;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, selecione uma data';
                          }
                          return null;
                        },
                      ),
                      MultiSelectDialogField(
                        items: _itens,
                        title: Text('Tasks dependentes'),
                        selectedColor: Colors.blue,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          border: Border.all(color: Colors.blue, width: 1),
                        ),
                        buttonIcon:
                            Icon(Icons.arrow_drop_down, color: Colors.blue),
                        buttonText: Text(
                          "Tasks dependentes",
                          style:
                              TextStyle(color: Colors.blue[800], fontSize: 16),
                        ),
                        onConfirm: (results) {
                          _selecionadas = results.cast<String>();
                        },
                      ),
                      TextFormField(
                        decoration:
                            InputDecoration(labelText: 'Descrição da task'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira a descrição da task';
                          }
                          return null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Selecione o nivel de prioridade',
                          border: OutlineInputBorder(),
                        ),
                        value: _prioridadeSelecionada,
                        items: _prioridade.map((opcao) {
                          return DropdownMenuItem(
                            value: opcao,
                            child: Text(opcao),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _prioridadeSelecionada = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Por favor, selecione uma opção';
                          }
                          return null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Selecione o nivel da task',
                          border: OutlineInputBorder(),
                        ),
                        value: _nivelSelecionado,
                        items: _nivel.map((nivel) {
                          return DropdownMenuItem(
                            value: nivel,
                            child: Text(nivel),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _nivelSelecionado = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Por favor, selecione um nivel de task';
                          }
                          return null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Selecione o responsavel da task',
                          border: OutlineInputBorder(),
                        ),
                        value: _responsavelSelecionado,
                        items: _responsaveis.map((resposavel) {
                          return DropdownMenuItem(
                            value: resposavel,
                            child: Text(resposavel),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _responsavelSelecionado = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Task'),
      ),
      body: const Center(
        child: Text('Conteúdo principal da página de tasks'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarModalDeCadastro(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
