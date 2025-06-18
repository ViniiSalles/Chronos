import 'package:flutter/material.dart';
import 'package:code/components/mobile_layout.dart';
import 'package:code/components/Tasks/project_card.dart' as card;
import 'package:code/servicesMobile/project_service.dart' as service;
import 'package:code/components/home/project_edit_modal.dart';
import 'package:code/components/home/project_delete_modal.dart';

class ProjectListMobilePage extends StatefulWidget {
  const ProjectListMobilePage({super.key});

  @override
  State<ProjectListMobilePage> createState() => _ProjectListMobilePageState();
}

class _ProjectListMobilePageState extends State<ProjectListMobilePage> {
  List<service.Project> _projects = [];
  bool _isLoading = true;

  card.Project _convertToCardProject(service.Project serviceProject) {
    return card.Project(
      id: serviceProject.id,
      name: serviceProject.nome,
      description: serviceProject.descricao ?? '',
      startDate: serviceProject.dataInicio,
      plannedEndDate: serviceProject.dataFim,
      status: serviceProject.status
          ? card.ProjectStatus.inProgress
          : card.ProjectStatus.completed,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    try {
      final projects = await service.ProjectService.getMyProjects();
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar projetos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditModal(service.Project project) {
    showDialog(
      context: context,
      builder: (context) => ProjectEditModal(
        project: project,
        onSuccess: _loadProjects,
      ),
    );
  }

  void _showDeleteModal(service.Project project) {
    showDialog(
      context: context,
      builder: (context) => ProjectDeleteModal(
        projectId: project.id,
        projectName: project.nome,
        onSuccess: _loadProjects,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    final theme = Theme.of(context);

    return MobileLayout(
      title: 'Projetos',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum projeto encontrado',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProjects,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12.0),
                    itemCount: _projects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final serviceProject = _projects[index];
                      final cardProject = _convertToCardProject(serviceProject);
                      return Stack(
                        children: [
                          card.ProjectCard(
                            project: cardProject,
                            isSmall: isSmall,
                            onTap: () {
                              // Aqui você pode navegar para detalhes do projeto ou quadro Kanban
                            },
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
    );
  }
}
