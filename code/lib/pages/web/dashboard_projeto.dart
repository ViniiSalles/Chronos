import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

// --- CLASSES DE DADOS (Sem alterações) ---
class Colaborador {
  final String nome;
  final String inicial;
  final int taskCount;

  const Colaborador({
    required this.nome,
    required this.inicial,
    required this.taskCount,
  });
}

class TaskStatusByComplexity {
  final String complexity;
  final int onTime;
  final int overdue;

  const TaskStatusByComplexity({
    required this.complexity,
    required this.onTime,
    required this.overdue,
  });
}

class DashboardProjeto extends StatefulWidget {
  const DashboardProjeto({super.key});

  @override
  State<DashboardProjeto> createState() => _DashboardProjetoState();
}

class _DashboardProjetoState extends State<DashboardProjeto> {
  // Dados para os gráficos agora são dinâmicos
  Map<String, double> taskData = {
    'A': 0,
    'B': 0,
    'C': 0,
    'D': 0,
  };
  Map<String, double> statusData = {
    'Completas': 0,
    'Pendentes': 0,
  };
  Map<String, double> priorityData = {
    'Baixa': 0,
    'Média': 0,
    'Alta': 0,
  };

  // *** ALTERAÇÃO 1: Remover 'final' para tornar a lista de colaboradores mutável ***
  List<Colaborador> colaboradores = [];

  // Variáveis de estado para os KPIs
  int? membrosEquipe;
  int? totalTarefas;
  int? diasRestantes;

  // Dados e configurações que não mudam
  final List<Color> barColors = const [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
  ];
  final List<Color> statusColors = const [
    Colors.teal,
    Colors.amber,
  ];
  final List<Color> priorityColors = const [
    Colors.lightGreen,
    Colors.orangeAccent,
    Colors.redAccent,
  ];
  final Color onTimeColor = Colors.cyan;
  final Color overdueColor = Colors.pink;
  Map<String, String> projects = {};
  String? selectedProject;
  String? selectedProjectId;

  @override
  void initState() {
    super.initState();
    getProjects();
  }

  void getProjects() async {
    // ... (código sem alteração)
    try {
      final url =
          Uri.parse('https://chronos-production-f584.up.railway.app/project');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> projectList = json.decode(response.body);
        setProjectsArray(projectList);
      } else {
        print('Erro ao buscar dados: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro na requisição: $e');
    }
  }

  void setProjectsArray(List<dynamic> array) {
    // ... (código sem alteração)
    var projectMap = <String, String>{};
    for (var project in array) {
      if (project is Map &&
          project.containsKey('nome') &&
          project.containsKey('_id')) {
        projectMap[project["nome"]] = project["_id"];
      }
    }
    setState(() {
      projects.addAll(projectMap);
    });
  }

  void handleProjectChange() async {
    if (selectedProjectId == null) {
      print("Nenhum projeto selecionado.");
      return;
    }
    try {
      final url = Uri.parse(
          'https://chronos-production-f584.up.railway.app/project/$selectedProjectId/report');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dynamic reportData = json.decode(response.body);

        // *** ALTERAÇÃO 2: Processar a lista de colaboradores corretamente ***
        final List<dynamic> rawColabs = reportData['tasksPerMember'] ?? [];
        final List<Colaborador> newColaboradores = rawColabs.map((colab) {
          final String nome = colab['nome'] ?? 'N/A';
          // *** ALTERAÇÃO 3: Corrigir a sintaxe para pegar a inicial ***
          final String inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';
          final int taskCount = (colab['count'] ?? 0).toInt();

          return Colaborador(
              nome: nome, inicial: inicial, taskCount: taskCount);
        }).toList();

        // Agrupar todas as atualizações de estado em um único setState
        setState(() {
          // Atualiza KPIs
          membrosEquipe = (reportData["numberOfMembers"] ?? 0).toInt();
          totalTarefas = (reportData["numberOfTasks"] ?? 0).toInt();
          diasRestantes = (reportData["daysRemaining"] ?? 0).toInt();

          // Atualiza dados dos gráficos
          statusData["Completas"] =
              (reportData['completedTasks'] ?? 0).toDouble();
          statusData["Pendentes"] =
              (reportData['pendingTasks'] ?? 0).toDouble();

          taskData["A"] =
              (reportData['tasksByComplexity']['A'] ?? 0).toDouble();
          taskData["B"] =
              (reportData['tasksByComplexity']['B'] ?? 0).toDouble();
          taskData["C"] =
              (reportData['tasksByComplexity']['C'] ?? 0).toDouble();
          taskData["D"] =
              (reportData['tasksByComplexity']['D'] ?? 0).toDouble();

          priorityData['Baixa'] =
              (reportData['tasksByPriority']['Baixa'] ?? 0).toDouble();
          priorityData['Média'] =
              (reportData['tasksByPriority']['Média'] ?? 0).toDouble();
          priorityData['Alta'] =
              (reportData['tasksByPriority']['Alta'] ?? 0).toDouble();

          // *** ALTERAÇÃO 4: Limpar a lista antiga e adicionar os novos colaboradores ***
          colaboradores.clear();
          colaboradores.addAll(newColaboradores);
        });
      } else {
        print('Erro ao buscar relatório: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro na requisição do relatório: $e');
    }
  }

  // --- MÉTODO BUILD E WIDGETS AUXILIARES ---

  @override
  Widget build(BuildContext context) {
    // ... (código sem alteração, apenas os gráficos comentados foram removidos para limpeza)
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop()),
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildKpiPanel(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildComplexityChart(),
                _buildStatusChart(),
                _buildPriorityChart(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCollaboratorsList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // O restante do código (widgets de build e funções auxiliares) permanece o mesmo.
  // Apenas o _buildCollaboratorsList agora irá renderizar a lista dinâmica corretamente.

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 300,
            child: Text(
              selectedProject ?? "Selecione um Projeto",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ),
          SizedBox(
            width: 200,
            child: DropdownButton<String>(
              hint: const Text("Selecione o projeto"),
              value: selectedProject,
              items: projects.keys
                  .map<DropdownMenuItem<String>>(
                      (String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ))
                  .toList(),
              onChanged: (String? newValue) {
                if (newValue == null) return;
                setState(() {
                  selectedProject = newValue;
                  selectedProjectId = projects[newValue];
                });
                handleProjectChange();
              },
              isExpanded: true,
              underline: Container(height: 1, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5)
            ]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildKpiItem(
                membrosEquipe?.toString() ?? "-", "Membros na Equipe"),
            _buildKpiItem(totalTarefas?.toString() ?? '-', "Total de Tarefas"),
            _buildKpiItem(
                diasRestantes != null
                    ? (diasRestantes! > 0
                        ? diasRestantes.toString()
                        : "Expirado!")
                    : '-',
                "Dias Restantes"),
          ],
        ),
      ),
    );
  }

  Widget _buildComplexityChart() {
    return Container(
        width: 450,
        height: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Tasks por Complexidade",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
              child: BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 30,
                  titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: _getComplexityBottomTitles,
                              reservedSize: 38)),
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: 10)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false))),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: _generateComplexityBarGroups())))
        ]));
  }

  Widget _buildStatusChart() {
    return Container(
        width: 450,
        height: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5)
            ]),
        child: Column(children: [
          const Text("Status das Tarefas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
              child: Row(children: [
            Expanded(
                flex: 2,
                child: PieChart(PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    sections: _buildPieChartSections()))),
            Expanded(
                flex: 1,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIndicator(
                          color: statusColors[0], text: 'Completas'),
                      const SizedBox(height: 8),
                      _buildIndicator(color: statusColors[1], text: 'Pendentes')
                    ]))
          ]))
        ]));
  }

  Widget _buildPriorityChart() {
    return Container(
        width: 450,
        height: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Tasks por Prioridade",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
              child: BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 30,
                  titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: _getPriorityBottomTitles,
                              reservedSize: 38)),
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: 10)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false))),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: _generatePriorityBarGroups())))
        ]));
  }

  Widget _buildCollaboratorsList() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5)
                ]),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Colaboradores e Tarefas",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Agora este map funciona com a lista 'colaboradores' dinâmica
              ...colaboradores.map((colab) => ListTile(
                  leading: CircleAvatar(child: Text(colab.inicial)),
                  title: Text(colab.nome,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: Chip(
                      label: Text(colab.taskCount.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2))))
            ])));
  }

  Widget _buildKpiItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A linha duplicada foi removida daqui.
        Text(
          value,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  List<BarChartGroupData> _generateComplexityBarGroups() {
    return taskData.entries.toList().asMap().entries.map((entry) {
      final int index = entry.key;
      final MapEntry<String, double> data = entry.value;
      return BarChartGroupData(x: index, barRods: [
        BarChartRodData(
            toY: data.value,
            color: barColors[index % barColors.length],
            width: 22,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6), topRight: Radius.circular(6)))
      ]);
    }).toList();
  }

  Widget _getComplexityBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
        color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 14);
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('A', style: style);
        break;
      case 1:
        text = const Text('B', style: style);
        break;
      case 2:
        text = const Text('C', style: style);
        break;
      case 3:
        text = const Text('D', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }
    return SideTitleWidget(
      space: 10,
      meta: meta,
      child: text,
    );
  }

  List<BarChartGroupData> _generatePriorityBarGroups() {
    return priorityData.entries.toList().asMap().entries.map((entry) {
      final int index = entry.key;
      final MapEntry<String, double> data = entry.value;
      return BarChartGroupData(x: index, barRods: [
        BarChartRodData(
            toY: data.value,
            color: priorityColors[index % priorityColors.length],
            width: 22,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6), topRight: Radius.circular(6)))
      ]);
    }).toList();
  }

  Widget _getPriorityBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
        color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 14);
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('Baixa', style: style);
        break;
      case 1:
        text = const Text('Média', style: style);
        break;
      case 2:
        text = const Text('Alta', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }
    return SideTitleWidget(
      space: 10,
      meta: meta,
      child: text,
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    return statusData.entries.toList().asMap().entries.map((entry) {
      final int index = entry.key;
      final MapEntry<String, double> data = entry.value;
      return PieChartSectionData(
          color: statusColors[index % statusColors.length],
          value: data.value,
          title: '${data.value.toInt()}',
          radius: 60,
          titleStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white));
    }).toList();
  }

  Widget _buildIndicator({required Color color, required String text}) {
    return Row(children: <Widget>[
      Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(4),
              color: color)),
      const SizedBox(width: 8),
      Text(text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))
    ]);
  }
}
