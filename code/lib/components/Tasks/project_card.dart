import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:code/common/constants/app_colors.dart';

enum ProjectStatus {
  inProgress,
  completed,
  cancelled,
}

class Project {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime plannedEndDate;
  ProjectStatus status;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.plannedEndDate,
    this.status = ProjectStatus.inProgress,
  });
}

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;
  final bool isSmall;

  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.isSmall = false,
  });

  String _getStatusText(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.inProgress:
        return 'Em Progresso';
      case ProjectStatus.completed:
        return 'Concluído';
      case ProjectStatus.cancelled:
        return 'Cancelado';
    }
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.inProgress:
        return AppColors.primary;
      case ProjectStatus.completed:
        return AppColors.success;
      case ProjectStatus.cancelled:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: isSmall ? 16 : 18,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(project.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(project.status),
                      style: TextStyle(
                        color: _getStatusColor(project.status),
                        fontWeight: FontWeight.w600,
                        fontSize: isSmall ? 11 : 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                project.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: isSmall ? 12 : 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: isSmall ? 14 : 16,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Início: ${DateFormat('dd/MM/yyyy').format(project.startDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: isSmall ? 11 : 13,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.flag,
                    size: isSmall ? 14 : 16,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Término: ${DateFormat('dd/MM/yyyy').format(project.plannedEndDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: isSmall ? 11 : 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 