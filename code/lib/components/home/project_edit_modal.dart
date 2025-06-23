import 'package:flutter/material.dart';
import 'package:code/services/project_service.dart';
import 'package:code/common/constants/app_colors.dart';

class ProjectEditModal extends StatefulWidget {
  final Project project;
  final VoidCallback onSuccess;

  const ProjectEditModal({
    super.key,
    required this.project,
    required this.onSuccess,
  });

  @override
  State<ProjectEditModal> createState() => _ProjectEditModalState();
}

class _ProjectEditModalState extends State<ProjectEditModal> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late bool _status;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.nome);
    _descriptionController = TextEditingController(text: widget.project.descricao);
    _startDate = widget.project.dataInicio;
    _endDate = widget.project.dataFim;
    _status = widget.project.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveProject() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome do projeto é obrigatório')),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As datas são obrigatórias')),
      );
      return;
    }

    final updatedProject = Project(
      id: widget.project.id,
      nome: _nameController.text,
      descricao: _descriptionController.text,
      dataInicio: _startDate!,
      dataFim: _endDate!,
      status: _status,
      tasks: widget.project.tasks,
      users: widget.project.users,
    );

    try {
      final success = await ProjectService.updateProject(updatedProject);
      if (success != null) {
        if (mounted) {
          widget.onSuccess();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao atualizar projeto'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar projeto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Editar Projeto',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Projeto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, true),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_startDate != null
                        ? 'Início: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                        : 'Data de Início'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, false),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_endDate != null
                        ? 'Fim: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'Data de Término'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Projeto Ativo'),
              value: _status,
              onChanged: (value) {
                setState(() {
                  _status = value;
                });
              },
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
                  onPressed: _saveProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 