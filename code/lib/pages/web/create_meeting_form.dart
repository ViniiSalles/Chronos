import 'package:code/pages/web/agenda_page.dart';
import 'package:flutter/material.dart';
import 'package:code/common/constants/app_colors.dart';
import 'package:intl/intl.dart'; // Para formatar datas
import 'package:multi_select_flutter/multi_select_flutter.dart'; // Para selecionar participantes
import 'package:code/services/project_service.dart'; // Para buscar projetos
// Para o TaskStatus e TaskService (para buscar usuários)
import 'package:code/services/meeting_service.dart' hide MeetingType; // Para o MeetingService e MeetingType

class CreateMeetingForm extends StatefulWidget {
  final VoidCallback? onSuccess;

  const CreateMeetingForm({super.key, this.onSuccess});

  @override
  State<CreateMeetingForm> createState() => _CreateMeetingFormState();
}

class _CreateMeetingFormState extends State<CreateMeetingForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();

  List<Project> _userProjects = []; // Projetos do usuário logado
  String? _selectedProjectId; // ID do projeto selecionado
  List<Map<String, dynamic>> _projectUsers =
      []; // Usuários do projeto selecionado
  List<String> _selectedParticipantIds =
      []; // IDs dos participantes selecionados

  MeetingType? _selectedMeetingType; // Tipo de reunião selecionado

  bool _isLoadingProjects = true;
  bool _isLoadingUsers = false;
  bool _isSavingMeeting = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProjects();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _locationController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProjects() async {
    setState(() {
      _isLoadingProjects = true;
    });
    try {
      final fetchedProjects = await ProjectService.getMyProjects();
      if (!mounted) return;
      setState(() {
        _userProjects = fetchedProjects;
        _isLoadingProjects = false;
      });
      // Se houver projetos, selecione o primeiro por padrão e carregue seus usuários
      if (_userProjects.isNotEmpty) {
        _selectedProjectId = _userProjects.first.id;
        _fetchProjectUsers(_selectedProjectId!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingProjects = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar projetos: ${e.toString()}')),
        );
      });
    }
  }

  Future<void> _fetchProjectUsers(String projectId) async {
    setState(() {
      _isLoadingUsers = true;
      _projectUsers = []; // Limpa usuários anteriores
      _selectedParticipantIds = []; // Limpa participantes selecionados
    });
    try {
      // Encontre o projeto selecionado para obter a lista de usuários
      final selectedProject =
          _userProjects.firstWhere((p) => p.id == projectId);
      if (!mounted) return;

      setState(() {
        // Converte a lista de usuários do projeto para o formato MultiSelectItem espera (id, name)
        _projectUsers = selectedProject.users
            .map((userMap) => {
                  'id': userMap['id']?.toString() ?? '',
                  'name': userMap['nome']?.toString() ??
                      userMap['email']?.toString() ??
                      'Usuário Desconhecido',
                })
            .toList();
        _isLoadingUsers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingUsers = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Erro ao carregar usuários do projeto: ${e.toString()}')),
        );
      });
    }
  }

  Future<void> _selectDateTime(BuildContext context,
      TextEditingController controller, bool isDateOnly) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now()
          .subtract(const Duration(days: 365 * 5)), // 5 anos atrás
      lastDate:
          DateTime.now().add(const Duration(days: 365 * 5)), // 5 anos no futuro
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (isDateOnly) {
        setState(() {
          controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
        });
      } else {
        // Para data e hora
        if (context.mounted) {
          final TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.surface,
                    onSurface: AppColors.textPrimary,
                  ),
                ),
                child: child!,
              );
            },
          );

          if (pickedTime != null) {
            final DateTime finalDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            setState(() {
              controller.text =
                  DateFormat('dd/MM/yyyy HH:mm').format(finalDateTime);
            });
          }
        }
      }
    }
  }

  Future<void> _createMeeting() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um projeto para a reunião.')),
      );
      return;
    }

    if (_selectedParticipantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um participante.')),
      );
      return;
    }

    setState(() {
      _isSavingMeeting = true;
    });

    try {
      final String startTimeIso = DateFormat('dd/MM/yyyy HH:mm')
          .parse(_startTimeController.text)
          .toIso8601String();
      final String endTimeIso = DateFormat('dd/MM/yyyy HH:mm')
          .parse(_endTimeController.text)
          .toIso8601String();

      // Validação de datas: EndTime deve ser após StartTime
      final DateTime parsedStartTime = DateTime.parse(startTimeIso);
      final DateTime parsedEndTime = DateTime.parse(endTimeIso);
      if (parsedEndTime.isBefore(parsedStartTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'A data/hora de término deve ser posterior à de início.')),
        );
        setState(() => _isSavingMeeting = false);
        return;
      }

      final Meeting meeting = Meeting(
        id: '', // Será gerado pelo backend
        title: _titleController.text,
        projectId: _selectedProjectId!,
        projectName: _userProjects
            .firstWhere((p) => p.id == _selectedProjectId!)
            .nome, // Apenas para inicialização
        startTime: parsedStartTime,
        endTime: parsedEndTime,
        location:
            _locationController.text.isEmpty ? null : _locationController.text,
        type: _selectedMeetingType ?? MeetingType.OTHER,
        // No DTO do backend, participants é string[], não o formato do schema
        // O MeetingService.create no backend mapeia user: pId
        participants: _selectedParticipantIds, // Passa a lista de IDs
        minutes:
            _minutesController.text.isEmpty ? null : _minutesController.text,
      );

      final bool success = await MeetingService.createMeeting(
          meeting); // Chamar o serviço de backend

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reunião criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess
            ?.call(); // Dispara o callback para fechar o modal/navegar
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao criar reunião. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar reunião: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingMeeting = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Converter MeetingType enum para string para exibir no Dropdown
    final List<String> meetingTypes = MeetingType.values
        .map((e) => e.toString().split('.').last.replaceAll('_', ' '))
        .toList();

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Nova Reunião',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('Título da Reunião'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Informe o título.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration('Descrição/Pauta (Opcional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _isLoadingProjects
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    decoration: _inputDecoration('Projeto'),
                    value: _selectedProjectId,
                    items: _userProjects.map((project) {
                      return DropdownMenuItem(
                        value: project.id,
                        child: Text(project.nome),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProjectId = value;
                        if (value != null) {
                          _fetchProjectUsers(
                              value); // Carrega usuários do novo projeto
                        }
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Selecione um projeto.' : null,
                  ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startTimeController,
                    readOnly: true,
                    decoration: _inputDecoration('Data/Hora Início',
                        icon: Icons.calendar_today),
                    onTap: () =>
                        _selectDateTime(context, _startTimeController, false),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Informe a data/hora de início.'
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _endTimeController,
                    readOnly: true,
                    decoration: _inputDecoration('Data/Hora Fim',
                        icon: Icons.calendar_today),
                    onTap: () =>
                        _selectDateTime(context, _endTimeController, false),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Informe a data/hora de término.'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: _inputDecoration('Local/Link da Reunião (Opcional)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MeetingType>(
              decoration: _inputDecoration('Tipo de Reunião'),
              value: _selectedMeetingType,
              items: MeetingType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type
                      .toString()
                      .split('.')
                      .last
                      .replaceAll('_', ' ')), // Formata o enum para exibição
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedMeetingType = value),
              validator: (value) =>
                  value == null ? 'Selecione o tipo de reunião.' : null,
            ),
            const SizedBox(height: 16),
            _isLoadingUsers
                ? const Center(child: CircularProgressIndicator())
                : MultiSelectDialogField(
                    initialValue: _selectedParticipantIds,
                    items: _projectUsers
                        .map((user) => MultiSelectItem<String>(
                              user['id']!,
                              user['name']!,
                            ))
                        .toList(),
                    title: const Text("Participantes"),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.primary.withOpacity(0.5)),
                    ),
                    buttonText: const Text("Selecionar Participantes"),
                    buttonIcon: const Icon(Icons.arrow_drop_down),
                    onConfirm: (values) {
                      setState(() {
                        _selectedParticipantIds = values.cast<String>();
                      });
                    },
                    validator: (values) => values == null || values.isEmpty
                        ? 'Selecione ao menos um participante.'
                        : null,
                  ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minutesController,
              decoration: _inputDecoration('Ata da Reunião (Opcional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isSavingMeeting ? null : _createMeeting,
                icon: _isSavingMeeting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _isSavingMeeting ? 'Salvando...' : 'Criar Reunião',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
