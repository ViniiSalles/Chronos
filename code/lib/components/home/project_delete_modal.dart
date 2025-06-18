import 'package:flutter/material.dart';
import 'package:code/servicesMobile/project_service.dart';
import 'package:code/common/constants/app_colors.dart';

class ProjectDeleteModal extends StatelessWidget {
  final String projectId;
  final String projectName;
  final VoidCallback onSuccess;

  const ProjectDeleteModal({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.onSuccess,
  });

  Future<void> _deleteProject(BuildContext context) async {
    final success = await ProjectService.deleteProject(projectId);
    if (success) {
      if (context.mounted) {
        onSuccess();
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir projeto')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Excluir Projeto',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tem certeza que deseja excluir o projeto "$projectName"? Esta ação não pode ser desfeita.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _deleteProject(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Excluir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 