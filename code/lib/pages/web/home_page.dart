import 'package:code/components/home/kanbanprojectview.dart';
import 'package:flutter/material.dart';
import 'package:code/common/constants/app_colors.dart';
import 'package:code/components/home/topbar.dart';
import 'package:code/components/home/sidebar.dart';
import 'package:code/components/Tasks/task_registration_page.dart';
import 'package:code/components/Tasks/tasks_by_project.dart'; // Presumindo que este é o widget ProjectTask
import 'package:code/components/search_filter_card.dart';
import 'package:code/services/project_service.dart'; // Importa o ProjectService e a classe Project

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Project> projetos = []; // Lista de projetos obtidos do ProjectService
  List<Project> _activeProjectsWithTasks =
      []; // Para armazenar projetos com tarefas agrupadas
  bool isLoading = true;
  bool _showSearchFilter = false;
  Project? _selectedProject; // O projeto atualmente selecionado na Sidebar

  // Opções para o formulário de registro de tarefas
  final List<String> _prioridadeOptionsForForm = ['Alta', 'Média', 'Baixa'];
  final List<String> _nivelOptionsForForm = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _loadProjectsAndTasks(); // Alterado para carregar projetos e suas tarefas
  }

  // Novo método para buscar e agrupar projetos e tarefas
  Future<void> _loadProjectsAndTasks() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 1. Carregar todos os projetos do usuário
      final fetchedProjects = await ProjectService.getMyProjects();

      // Se sua API de `my-projects` já retorna o projeto com as tarefas aninhadas:
      if (!mounted) return;
      setState(() {
        projetos = fetchedProjects;
        _activeProjectsWithTasks =
            fetchedProjects; // Usar os projetos carregados diretamente
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar projetos e tarefas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método para lidar com a seleção de um projeto na Sidebar
  void _handleProjectSelection(Project project) {
    setState(() {
      _selectedProject = project;
    });
  }

  // Método para abrir o formulário de registro de tarefa
  void _abrirFormularioTask({
    required String projectId,
    required List<Map<String, dynamic>> tasksProjeto,
    required List<Map<String, dynamic>> usersProjeto,
  }) {
    // Formata as tarefas existentes para o formato esperado pelo TaskFormDialog
    final List<Map<String, dynamic>> tarefasExistentesFormatadas = [];
    for (var item in tasksProjeto) {
      tarefasExistentesFormatadas
          .add({"id": item['_id'], "name": item['titulo']});
    }

    // Formata a lista de responsáveis para o formato esperado pelo TaskFormDialog
    final List<Map<String, dynamic>> responsaveisFormatados = [];
    for (var userMap in usersProjeto) {
      responsaveisFormatados
          .add({"id": userMap['id'], "name": userMap['nome']});
    }

    showDialog(
      context: context,
      builder: (context) => TaskFormDialog(
        id: projectId, // Passa o ID do projeto
        tarefasExistentes: tarefasExistentesFormatadas,
        prioridades:
            _prioridadeOptionsForForm, // Usando as opções de prioridade globais
        niveis: _nivelOptionsForForm, // Usando as opções de nível globais
        responsaveis: responsaveisFormatados,
      ),
    ).then((_) {
      _loadProjectsAndTasks(); // Recarrega projetos e tarefas após fechar o formulário
    });
  }

  void _handleFilter(String searchText, String type, String sort) {
    print('Search: $searchText, Type: $type, Sort: $sort');
    // Implementar a lógica de filtragem aqui
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh:
                      _loadProjectsAndTasks, // Recarrega tudo ao puxar para atualizar
                  child: Row(
                    children: [
                      Sidebar(
                        projetos: projetos,
                        projetoSelecionadoNome: _selectedProject?.nome,
                        onProjectSelected: _handleProjectSelection,
                        onSearchClick: () {
                          setState(() {
                            _showSearchFilter = !_showSearchFilter;
                          });
                        },
                        isSearchSelected: _showSearchFilter,
                        onProjectsUpdated:
                            _loadProjectsAndTasks, // Callback para atualizar a lista de projetos
                      ),
                      Expanded(
                        child: _selectedProject ==
                                null // Se nenhum projeto estiver selecionado na sidebar
                            ? Column(
                                children: [
                                  const TopBar(), // Sua barra superior
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 24,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Minhas tasks',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              // Este botão de adicionar tarefa geral foi removido,
                                              // pois você já tem um botão "adicionar" por projeto.
                                              // Se você quiser um botão "adicionar tarefa" geral, ele precisaria
                                              // de uma lógica para perguntar a qual projeto a tarefa pertence.
                                            ],
                                          ),
                                          const Divider(height: 32),
                                          Expanded(
                                            child: _activeProjectsWithTasks
                                                    .isEmpty
                                                ? const Center(
                                                    child: Text(
                                                        "Nenhum projeto para exibir tasks.",
                                                        style: TextStyle(
                                                            color: AppColors
                                                                .textSecondary)),
                                                  )
                                                : ListView.builder(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 16.0,
                                                        vertical: 8.0),
                                                    itemCount:
                                                        _activeProjectsWithTasks
                                                            .length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final project =
                                                          _activeProjectsWithTasks[
                                                              index];
                                                      return Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        bottom:
                                                                            8.0,
                                                                        top:
                                                                            16.0),
                                                                child: Text(
                                                                  project.nome,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: AppColors
                                                                        .textPrimary,
                                                                  ),
                                                                ),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () =>
                                                                    _abrirFormularioTask(
                                                                  projectId:
                                                                      project
                                                                          .id,
                                                                  tasksProjeto:
                                                                      project
                                                                          .tasks,
                                                                  usersProjeto:
                                                                      project
                                                                          .users, // Passa a lista de usuários do projeto
                                                                ),
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                      AppColors
                                                                          .primary,
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white,
                                                                  shape:
                                                                      RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            20),
                                                                  ),
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .symmetric(
                                                                    horizontal:
                                                                        32,
                                                                    vertical:
                                                                        12,
                                                                  ),
                                                                  elevation: 2,
                                                                ),
                                                                child: const Icon(
                                                                    Icons.add),
                                                              ),
                                                            ],
                                                          ),
                                                          ProjectTask(
                                                            projectName:
                                                                project.nome,
                                                            tasks:
                                                                project.tasks,
                                                            fetchData: (Map<
                                                                    String,
                                                                    dynamic>
                                                                task) {
                                                              _loadProjectsAndTasks(); // Recarrega após mudança de tarefa
                                                            },
                                                            // O projectId aqui é passado para ProjectTask, se ele precisar para algo interno
                                                            // mas não é usado na função fetchData que você definiu.
                                                            projectId:
                                                                project.id,
                                                          ),
                                                          if (index <
                                                              _activeProjectsWithTasks
                                                                      .length -
                                                                  1)
                                                            const Divider(
                                                                height: 20,
                                                                thickness: 0.5),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : KanbanProjectView(
                                projectName: _selectedProject!.nome,
                                projectId: _selectedProject!.id,
                                projectStartDate: _selectedProject!.dataInicio,
                                onBack: () {
                                  setState(() {
                                    _selectedProject = null;
                                  });
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                if (_showSearchFilter)
                  Positioned(
                    top: 100,
                    left: 240, // Ajuste a posição conforme seu layout
                    child: SearchFilterCard(
                      onFilter: _handleFilter,
                      onClose: () {
                        setState(() {
                          _showSearchFilter = false;
                        });
                      },
                    ),
                  ),
              ],
            ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.pushNamed(context, '/project-registration').then((_) {
      //       _loadProjectsAndTasks(); // Recarrega projetos após registrar um novo
      //     });
      //   },
      //   backgroundColor: AppColors.primary,
      //   foregroundColor: Colors.white,
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
