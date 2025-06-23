import 'package:code/pages/project_user_page.dart';
import 'package:code/pages/web/agenda_page.dart';
import 'package:code/pages/web/user_dashboard_page.dart'; // 1. IMPORTAR a nova página
import 'package:flutter/material.dart';
import 'package:code/common/constants/app_colors.dart';
import 'package:code/components/home/sidebaricon.dart';
import 'package:code/pages/project_registration_page.dart';
import 'package:code/services/project_service.dart';
import 'package:code/components/home/project_edit_modal.dart';
import 'package:code/components/home/project_delete_modal.dart';
import 'package:code/components/notification/notification_popup.dart';
import 'package:code/pages/web/dashboard_projeto.dart';

class Sidebar extends StatelessWidget {
  final List<Project> projetos;
  final String? projetoSelecionadoNome;
  final void Function(Project project) onProjectSelected;
  final VoidCallback onSearchClick;
  final bool isSearchSelected;
  final VoidCallback onProjectsUpdated;

  const Sidebar({
    super.key,
    required this.projetos,
    this.projetoSelecionadoNome,
    required this.onProjectSelected,
    required this.onSearchClick,
    required this.isSearchSelected,
    required this.onProjectsUpdated,
  });

  void _showNotificationPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return const NotificationPopup();
      },
    );
  }

  @override
  Widget build(BuildContext context) {


    return Container(
      width: 250,
      height: double.infinity,
      color: AppColors.primary,
      child: Column(
        children: [
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onSearchClick,
            child: SidebarIcon(
              icon: Icons.search,
              label: 'Pesquisar',
              selected: isSearchSelected,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _showNotificationPopup(context),
            child: const SidebarIcon(
              icon: Icons.notifications,
              label: 'Notificações',
              selected: false,
            ),
          ),
          const SizedBox(height: 24),

          // 2. NOVO BOTÃO "MINHA DASHBOARD"
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const UserDashboardPage()),
              );
            },
            child: const SidebarIcon(
              icon: Icons.person_outline,
              label: 'Minha Dashboard',
            ),
          ),
          const SizedBox(height: 24),

          // 3. BOTÃO EXISTENTE RENOMEADO
          GestureDetector(
            onTap: () {
              // Garante que um projeto válido seja passado
              // if (selectedProject.id.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DashboardProjeto()),
              );
              // } else {
              //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              //       content:
              //           Text("Selecione um projeto para ver a dashboard.")));
              // }
            },
            child: const SidebarIcon(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard do Projeto',
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AgendaPage()),
              );
            },
            child:
                const SidebarIcon(icon: Icons.calendar_today, label: 'Agenda'),
          ),
          const SizedBox(height: 32),
          const Divider(
            color: Colors.white24,
            thickness: 1,
            indent: 24,
            endIndent: 24,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meus Projetos',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return Dialog(
                                insetPadding: const EdgeInsets.all(24),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 400),
                                    child: ProjectRegistrationForm(
                                      onSuccess: () {
                                        Navigator.of(dialogContext).pop();
                                        onProjectsUpdated();
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        label: const Text('Novo Projeto'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (projetos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Nenhum projeto.',
                          style: TextStyle(
                              color: Colors.white70,
                              fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: projetos.length,
                        itemBuilder: (context, index) {
                          final projeto = projetos[index];
                          return _ProjectListItem(
                            key: ValueKey(projeto.id),
                            project: projeto,
                            isSelected: projetoSelecionadoNome == projeto.nome,
                            onTap: () => onProjectSelected(projeto),
                            onProjectsUpdated: onProjectsUpdated,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectListItem extends StatefulWidget {
  final Project project;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onProjectsUpdated;

  const _ProjectListItem({
    super.key,
    required this.project,
    required this.isSelected,
    required this.onTap,
    required this.onProjectsUpdated,
  });

  @override
  __ProjectListItemState createState() => __ProjectListItemState();
}

class __ProjectListItemState extends State<_ProjectListItem> {
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() {
    // ... (nenhuma alteração necessária aqui)
    return Future.sync(() async {
      if (widget.project.id.isNotEmpty) {
        final role =
            await ProjectService().getMyRoleInProject(widget.project.id);
        if (mounted) {
          setState(() {
            _userRole = role;
          });
        }
      }
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _showEditModal() {
    showDialog(
      context: context,
      builder: (dialogContext) => ProjectEditModal(
        project: widget.project,
        onSuccess: () {
          widget.onProjectsUpdated();
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  void _showDeleteModal() {
    showDialog(
      context: context,
      builder: (dialogContext) => ProjectDeleteModal(
        projectId: widget.project.id,
        projectName: widget.project.nome,
        onSuccess: () {
          widget.onProjectsUpdated();
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  void _navigateToAddMembers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectUserPage(
          projectId: widget.project.id,
          projectName: widget.project.nome,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                widget.project.nome,
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight:
                      widget.isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        if (_isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        else if (_userRole != "Dev")
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
            tooltip: "Opções do projeto",
            onSelected: (value) {
              if (value == 'edit') {
                _showEditModal();
              } else if (value == 'delete') {
                _showDeleteModal();
              } else if (value == 'add_member') {
                _navigateToAddMembers();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ]),
              ),
              const PopupMenuItem(
                value: 'add_member',
                child: Row(children: [
                  Icon(Icons.person_add, size: 20, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text('Adicionar Membro',
                      style: TextStyle(color: Colors.blueAccent)),
                ]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir', style: TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),
      ],
    );
  }
}
