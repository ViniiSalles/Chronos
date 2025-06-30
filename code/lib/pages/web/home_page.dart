import 'dart:async';
import 'package:code/services/task_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:code/components/home/kanbanprojectview.dart';
import 'package:flutter/material.dart';
import 'package:code/common/constants/app_colors.dart';
import 'package:code/components/home/topbar.dart';
import 'package:code/components/home/sidebar.dart';
import 'package:code/components/Tasks/task_registration_page.dart';
import 'package:code/components/Tasks/tasks_by_project.dart';
import 'package:code/components/search_filter_card.dart';
import 'package:code/services/project_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Variáveis de estado existentes
  List<Project> projetos = [];
  List<Project> _activeProjectsWithTasks = [];
  bool isLoading = true;
  bool _showSearchFilter = false;
  Project? _selectedProject;
  final List<String> _prioridadeOptionsForForm = ['Alta', 'Média', 'Baixa'];
  final List<String> _nivelOptionsForForm = ['A', 'B', 'C', 'D'];

  // Variáveis para o WebSocket
  IO.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _loadProjectsAndTasks();
    _connectToSocket(); // Inicia a conexão com o WebSocket
  }

  @override
  void dispose() {
    _disconnectFromSocket(); // Encerra a conexão ao sair da tela
    super.dispose();
  }

  void _connectToSocket() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('WebSocket: Usuário não logado.');
      return;
    }

    if (_socket != null && _socket!.connected) return;

    _disconnectFromSocket();

    _socket = IO
        .io('https://chronos-production-f584.up.railway.app', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'query': {'firebaseUid': currentUser.uid},
    });

    _socket!.onConnect((_) {
      print('WebSocket: Conectado com sucesso com o ID: ${_socket?.id}');
    });

    _socket!.on('taskCreated', (data) {
      print('WebSocket: Evento "taskCreated" recebido!');
      if (mounted) {
        // Exibe o toast genérico de notificação
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            // MODIFICADO: O texto do toast agora é genérico.
            content: Text('Você tem uma nova notificação!'),
            backgroundColor:
                AppColors.primary, // Cor ajustada para o padrão do app
          ),
        );
        // Recarrega os projetos e tarefas para exibir os novos dados
        _loadProjectsAndTasks();
      }
    });

    _socket!.onDisconnect((_) => print('WebSocket: Desconectado.'));
    _socket!.onError((error) => print('WebSocket: Erro de conexão - $error'));
  }

  void _disconnectFromSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  Future<void> _loadProjectsAndTasks() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedProjects = await ProjectService.getMyProjects();
      if (!mounted) return;
      setState(() {
        projetos = fetchedProjects;
        _activeProjectsWithTasks = fetchedProjects;
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

  void _handleProjectSelection(Project project) {
    setState(() {
      _selectedProject = project;
    });
  }

  void _abrirFormularioTask({
    required String projectId,
    required List<Map<String, dynamic>> tasksProjeto,
    required List<Map<String, dynamic>> usersProjeto,
  }) {
    final List<Map<String, dynamic>> tarefasExistentesFormatadas = [];
    for (var item in tasksProjeto) {
      tarefasExistentesFormatadas
          .add({"id": item['_id'], "name": item['titulo']});
    }

    final List<Map<String, dynamic>> responsaveisFormatados = [];
    for (var userMap in usersProjeto) {
      responsaveisFormatados
          .add({"id": userMap['id'], "name": userMap['nome']});
    }

    showDialog(
      context: context,
      builder: (context) => TaskFormDialog(
        id: projectId,
        tarefasExistentes: tarefasExistentesFormatadas,
        prioridades: _prioridadeOptionsForForm,
        niveis: _nivelOptionsForForm,
        responsaveis: responsaveisFormatados,
      ),
    ).then((_) {
      _loadProjectsAndTasks();
    });
  }

  void _handleFilter(String searchText, String type, String sort) {
    print('Search: $searchText, Type: $type, Sort: $sort');
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
                  onRefresh: _loadProjectsAndTasks,
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
                        onProjectsUpdated: _loadProjectsAndTasks,
                      ),
                      Expanded(
                        child: _selectedProject == null
                            ? Column(
                                children: [
                                  const TopBar(),
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
                                          const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Minhas tasks',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
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
                                                                          .users,
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
                                                              _loadProjectsAndTasks();
                                                            },
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
                    left: 240,
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
    );
  }
}
