import 'package:flutter/material.dart';
import 'package:code/common/constants/app_colors.dart';
import 'package:code/servicesMobile/task_service.dart';

class TaskStatusModal extends StatelessWidget {
  final Task task;
  final Function(TaskStatus) onStatusChanged;

  const TaskStatusModal({
    super.key,
    required this.task,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alterar Status',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              task.title,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            _buildStatusOption(context, 'pending', 'Pendente', Icons.schedule),
            _buildStatusOption(context, 'in_progress', 'Em Andamento', Icons.play_circle),
            _buildStatusOption(context, 'done', 'Concluída', Icons.check_circle),
            _buildStatusOption(context, 'cancelled', 'Cancelada', Icons.cancel),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(BuildContext context, String status, String label, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = TaskService.getStatusString(task.status) == status;

    return InkWell(
      onTap: () {
        final newStatus = TaskService.parseStatus(status);
        onStatusChanged(newStatus);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? _getStatusColor(status).withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _getStatusColor(status),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isSelected ? _getStatusColor(status) : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Icon(
                Icons.check_circle,
                color: _getStatusColor(status),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.primary;
      case 'done':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }
} 