import 'package:code/pages/web/create_meeting_page.dart';
import 'package:code/services/task_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:code/common/constants/app_colors.dart';
import 'package:code/services/meeting_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';


// Definindo MeetingType para o frontend (pode ser útil aqui)
enum MeetingType {
  DAILY_SCRUM,
  SPRINT_PLANNING,
  SPRINT_REVIEW,
  SPRINT_RETROSPECTIVE,
  REFINEMENT,
  OTHER,
}

// Classe Meeting no Frontend (completa e corrigida)
class Meeting {
  final String id;
  final String title;
  final String? description; // Adicionado description
  final String projectId;
  final String projectName;
  final DateTime startTime;
  final DateTime endTime;
  final MeetingType type;
  final String? location;
  final List<String> participants;
  final String? minutes;

  Meeting({
    required this.id,
    required this.title,
    this.description, // Adicionado ao construtor
    required this.projectId,
    required this.projectName,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.location,
    required this.participants,
    this.minutes,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(), // Parsear description
      projectId: json['project'] is String
          ? (json['project']?.toString() ?? '')
          : ((json['project'] as Map<String, dynamic>?)?['_id']?.toString() ?? ''),
      projectName: (json['project'] is Map<String, dynamic> &&
              json['project']['nome'] != null)
          ? json['project']['nome']?.toString() ?? 'N/A'
          : 'N/A',
      startTime: DateTime.parse(json['startTime'].toString()),
      endTime: DateTime.parse(json['endTime'].toString()),
      type: _parseMeetingType(json['type']?.toString()),
      location: json['location']?.toString(),
      // CORREÇÃO AQUI: Parsear participants corretamente como List<String> de IDs
      participants: (json['participants'] is List)
          ? (json['participants'] as List)
              .map((p) => p is Map<String, dynamic> ? p['user']?.toString() ?? '' : p?.toString() ?? '') // Se for array de {user:id} ou array de IDs
              .where((id) => id.isNotEmpty) // Filtra IDs vazios
              .toList()
          : [],
      minutes: json['minutes']?.toString(),
    );
  }

  // Removido get description => null;
  // O campo 'description' já está definido como final String? description;

  static MeetingType _parseMeetingType(String? type) {
    if (type == null) return MeetingType.OTHER;
    switch (type) {
      case 'Daily Scrum':
        return MeetingType.DAILY_SCRUM;
      case 'Sprint Planning':
        return MeetingType.SPRINT_PLANNING;
      case 'Sprint Review':
        return MeetingType.SPRINT_REVIEW;
      case 'Sprint Retrospective':
        return MeetingType.SPRINT_RETROSPECTIVE;
      case 'Refinement':
        return MeetingType.REFINEMENT;
      default:
        return MeetingType.OTHER;
    }
  }
}

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Task> _tasks = [];
  List<Meeting> _meetings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAgendaData();
  }

  Future<void> _fetchAgendaData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      setState(() {
        _errorMessage = 'Usuário não logado. Por favor, faça login novamente.';
        _isLoading = false;
      });
      return;
    }

    try {
      final List<Task> fetchedTasks = await TaskService.findAssignedTasksForUser();
      final List<Meeting> fetchedMeetings = await MeetingService.getAllMeetingsForUser(currentUserId);

      if (!mounted) return;

      setState(() {
        _tasks = fetchedTasks;
        _meetings = fetchedMeetings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao carregar agenda: ${e.toString()}';
        _isLoading = false;
      });
      print('Erro ao buscar dados da agenda: $e');
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final List<dynamic> events = [];
    events.addAll(_meetings.where((meeting) {
      // Reuniões que começam ou terminam no dia, ou abrangem o dia
      return (meeting.startTime.isBefore(day.add(const Duration(days: 1))) && meeting.endTime.isAfter(day))
          || isSameDay(meeting.startTime, day)
          || isSameDay(meeting.endTime, day);
    }).toList());
    events.addAll(_tasks.where((task) {
      // Tarefas com data limite no dia
      return task.deadline != null && isSameDay(task.deadline!, day);
    }).toList());
    return events;
  }

  Color _getTaskStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return AppColors.success;
      case TaskStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String _getTaskStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pendente';
      case TaskStatus.inProgress:
        return 'Em Progresso';
      case TaskStatus.completed:
        return 'Concluída';
      case TaskStatus.cancelled:
        return 'Cancelada';
      default:
        return 'Desconhecido';
    }
  }

  void _openCreateMeetingForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateMeetingPage()),
    ).then((_) {
      _fetchAgendaData(); // Recarrega os dados da agenda
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Minha Agenda',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Column(
                      children: [
                        TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          selectedDayPredicate: (day) {
                            return isSameDay(_selectedDay, day);
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onFormatChanged: (format) {
                            if (_calendarFormat != format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            }
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                          eventLoader: _getEventsForDay,
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            weekendTextStyle: const TextStyle(color: Colors.red),
                            selectedDecoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            markersMaxCount: 3,
                          ),
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                          ),
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, day, focusedDay) {
                              final events = _getEventsForDay(day);
                              if (events.isNotEmpty) {
                                return Container(
                                  margin: const EdgeInsets.all(4.0),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(color: AppColors.secondary, width: 0.8),
                                  ),
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                  ),
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Expanded(
                          child: _selectedDay == null
                              ? const Center(child: Text('Selecione um dia para ver os eventos.'))
                              : ListView.builder(
                                  itemCount: _getEventsForDay(_selectedDay!).length,
                                  itemBuilder: (context, index) {
                                    final event = _getEventsForDay(_selectedDay!)[index];
                                    if (event is Meeting) {
                                      return Card(
                                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                        child: ListTile(
                                          leading: const Icon(Icons.meeting_room, color: AppColors.primary),
                                          title: Text(
                                            'Reunião: ${event.title}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Text(
                                            'Projeto: ${event.projectName} - ${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                                          ),
                                          onTap: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Clicou na reunião: ${event.title}')),
                                            );
                                          },
                                        ),
                                      );
                                    } else if (event is Task) {
                                      return Card(
                                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.task_alt,
                                            color: _getTaskStatusColor(event.status),
                                          ),
                                          title: Text(
                                            'Tarefa: ${event.title}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Text(
                                            'Projeto: ${event.projeto?.nome ?? 'N/A'} - Vence em: ${DateFormat('dd/MM/yyyy').format(event.deadline!)} - Status: ${_getTaskStatusText(event.status)}',
                                          ),
                                          onTap: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Clicou na tarefa: ${event.title}')),
                                            );
                                          },
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                        ),
                      ],
                    ),
          // Botão Absoluto
          Positioned(
            bottom: 16.0, // Distância do fundo
            right: 16.0, // Distância da direita
            child: FloatingActionButton(
              onPressed: _openCreateMeetingForm, // Chamada para abrir o formulário
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}