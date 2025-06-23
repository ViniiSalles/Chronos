import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:code/common/constants/app_colors.dart';

class TaskFormDialog extends StatefulWidget {
  final List<Map<String, dynamic>> tarefasExistentes;
  final List<String> prioridades;
  final List<String> niveis;
  final List<Map<String, dynamic>> responsaveis;
  final String? id;

  const TaskFormDialog({
    super.key,
    required this.tarefasExistentes,
    required this.prioridades,
    required this.niveis,
    required this.responsaveis,
    required this.id,
  });

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _dateController = TextEditingController();
  List<String> _selecionadas = [];
  List _recomendacao = [];
  String? _prioridadeSelecionada;
  String? _nivelSelecionado;
  String? _responsavelSelecionado;

  @override
  void initState() {
    super.initState();
    print(widget.tarefasExistentes);
  }
  

  void sendData() async {
    final url = Uri.parse('http://10.0.2.2:3000/tasks');
    User? user = FirebaseAuth.instance.currentUser;
    final String? token = await user?.getIdToken();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({
        "titulo": _tituloController.text,
        "descricao": _descricaoController.text,
        "prioridade": _prioridadeSelecionada,
        "complexidade": _nivelSelecionado,
        "projeto": widget.id,
        "dataInicio": DateTime.now().toIso8601String(),
        "dataLimite": _dateController.text.isNotEmpty
            ? DateFormat('dd/MM/yyyy').parse(_dateController.text).toIso8601String()
            : null,
        "status": "pending",
        "atribuicoes": [_responsavelSelecionado],
        "tarefasAnteriores": _selecionadas,
      }),
    );

    print(_selecionadas);

    // Exibe um alerta de sucesso ao salvar
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sucesso'),
          content: const Text('Cadastro salvo com sucesso!'),
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
    }
    // Limpa todos os campos após salvar
    _tituloController.clear();
    _descricaoController.clear();
    _dateController.clear();
    setState(() {
      _selecionadas = [];
      _prioridadeSelecionada = null;
      _nivelSelecionado = null;
      _responsavelSelecionado = null;
    });

    if (response.statusCode == 201) {
      // Limpa todos os campos após salvar
      _tituloController.clear();
      _descricaoController.clear();
      _dateController.clear();
      setState(() {
        _selecionadas = [];
        _prioridadeSelecionada = null;
        _nivelSelecionado = null;
        _responsavelSelecionado = null;
      });

      // Fecha o diálogo de cadastro
      Navigator.of(context).pop();

      // Mostra mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task cadastrada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
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

  void getRecomendation() async {
    var url = 'http://10.0.2.2:3000/tasks/recommendations?projeto=${widget.id}';

    if (_nivelSelecionado != null) {
      url = '$url&complexidade=$_nivelSelecionado';
    }

    if (_selecionadas.isNotEmpty) {
      for (var task in _selecionadas) {
        url = '$url&tarefasAnteriores=$task';
      }
    }

    final uri = Uri.parse(url);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      print('Resposta da requisição: ${response.body}');
      var usuarios = jsonDecode(response.body);
      // if (usuarios is List) { // Comentado pois a ordenação funciona mesmo se não for uma lista, mas pode gerar erro em runtime se não for.
      usuarios.sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));

      setState(() {
        _recomendacao = usuarios;
      });
      // }
    } else {
      print("algo deu errado ${response.body}");
    }
  }

  void _onFieldChanged() {
    getRecomendation();
  }

  @override
  Widget build(BuildContext context) {
    final itens = widget.tarefasExistentes
        .map((task) => MultiSelectItem<String>(
              task['id'],
              task['name'] ?? '',
            ))
        .toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Cadastro de Nova Task',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 1100,
        height: 450, // Pode precisar ajustar ou tornar mais dinâmico
        child: Column(
          children: [
            Expanded( // Para garantir que o SingleChildScrollView use o espaço disponível
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox( // Container para o formulário
                      width: 500, // Largura explícita para o formulário
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Não terá muito efeito aqui devido ao SingleChildScrollView
                          children: [
                            /// TÍTULO
                            SizedBox(
                              width: 500, // Define the width of the TextFormField
                              child: TextFormField(
                                controller: _tituloController,
                                decoration: _inputDecoration('Título da task'),
                                validator: (value) => value == null || value.isEmpty
                                    ? 'Informe um título'
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 16),

                            /// DATA E TASKS DEPENDENTES
                            Row(
                              children: [
                                SizedBox(
                                  width: 240,
                                  child: TextFormField( // Expanded removido pois o SizedBox já define a largura
                                    controller: _dateController,
                                    readOnly: true,
                                    decoration: _inputDecoration(
                                      'Data de entrega',
                                      icon: Icons.calendar_today,
                                    ),
                                    onTap: () async {
                                      DateTime? picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          _dateController.text =
                                              DateFormat('dd/MM/yyyy').format(picked);
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                SizedBox(
                                  width: 240,
                                  child: MultiSelectDialogField( // Expanded removido
                                    initialValue: _selecionadas,
                                    items: itens,
                                    title: const Text("Tasks dependentes"),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.shade300),
                                    ),
                                    buttonText: const Text("Selecionar dependências"),
                                    buttonIcon: const Icon(Icons.arrow_drop_down),
                                    onConfirm: (values) {
                                      _selecionadas = values.cast<String>();
                                      _onFieldChanged();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            /// DESCRIÇÃO
                            SizedBox(
                              width: 500,
                              child: TextFormField(
                                controller: _descricaoController,
                                decoration: _inputDecoration('Descrição'),
                                maxLines: 4,
                                validator: (value) => value == null || value.isEmpty
                                    ? 'Informe a descrição'
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 25),

                            /// PRIORIDADE, NÍVEL, RESPONSÁVEL
                            Row(
                              children: [
                                SizedBox(
                                  width: 150,
                                  child: DropdownButtonFormField<String>( // Expanded removido
                                    value: _prioridadeSelecionada,
                                    decoration: _inputDecoration('Prioridade'),
                                    items: widget.prioridades
                                        .map((p) =>
                                            DropdownMenuItem(value: p, child: Text(p)))
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => _prioridadeSelecionada = value),
                                    validator: (value) =>
                                        value == null ? 'Selecione a prioridade' : null,
                                  ),
                                ),
                                const SizedBox(width: 25),
                                SizedBox(
                                  width: 150,
                                  child: DropdownButtonFormField<String>( // Expanded removido
                                    value: _nivelSelecionado,
                                    decoration: _inputDecoration('Nível'),
                                    items: widget.niveis
                                        .map((n) =>
                                            DropdownMenuItem(value: n, child: Text(n)))
                                        .toList(),
                                    onChanged: (value) => {
                                      setState(() => _nivelSelecionado = value),
                                      _onFieldChanged()
                                    },
                                    validator: (value) =>
                                        value == null ? 'Selecione o nível' : null,
                                  ),
                                ),
                                const SizedBox(width: 25),
                                SizedBox(
                                  width: 148,
                                  child: DropdownButtonFormField<String>(
                                    // Expanded removido
                                    value: _responsavelSelecionado,
                                    decoration: _inputDecoration('Resp.'),
                                    items: widget.responsaveis
                                        .map((r) => DropdownMenuItem(
                                              value: r['id'].toString(),
                                              child: Text(r['name'] ?? ''),
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
                            const SizedBox(height: 32), // Espaço no final do formulário
                          ],
                        ),
                      ),
                    ),
                    SizedBox( // Container para as recomendações
                      width: 500, // Largura explícita para as recomendações
                      child: Container(
                        margin: const EdgeInsets.only(left: 20), // Reduzida a margem para melhor encaixe ou ajuste conforme necessário
                        padding: const EdgeInsets.only(top: 8), // Espaço para o título "Recomendações"
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recomendações de Responsáveis',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            _recomendacao.isEmpty
                                ? const Text(
                                    'Nesta area serão exibidos as recomendações de usuarios para associação a task, quanto maior o seu score, maior sua afinidade com a mesma :)')
                                : SizedBox(
                                    height: 300, // Defina uma altura fixa para a lista
                                    child: ListView.builder(
                                      itemCount: _recomendacao.length,
                                      itemBuilder: (context, index) {
                                        final rec = _recomendacao[index];
                                        return ListTile(
                                          title: Text(rec['nome'] ?? 'Nome não disponível'),
                                          subtitle: Text('Score: ${rec['score']}'),
                                        );
                                      },
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            Padding( // Adicionado Padding para os botões
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
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
                        sendData();
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
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }
}