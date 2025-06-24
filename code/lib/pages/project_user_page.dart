import 'package:code/common/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProjectUserPage extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ProjectUserPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ProjectUserPage> createState() => _ProjectUserPageState();
}

class _ProjectUserPageState extends State<ProjectUserPage> {
  List<Map<String, String>> teamMembers = [];

  String? selectedUserId;
  String? selectedRole;

  Map<String, Map<String, String>> availableUsers = {};

  Future<void> fetchProjectMembers() async {
    final url = Uri.parse(
        'https://chronos-production-f584.up.railway.app/project/${widget.projectId}/members');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> members = jsonDecode(response.body);

        setState(() {
          teamMembers.clear();
          teamMembers.addAll(
            members.map((member) {
              return {
                'id': member['id'],
                'name': member['nome'],
                'email': member['email'],
                'role': member['papel'],
                'avatar': '',
              };
            }),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Erro ao buscar membros do projeto: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erro de rede ao tentar buscar membros do projeto.')),
      );
    }
  }

  Future<void> fetchAvailableUsers() async {
    final response = await http
        .get(Uri.parse('https://chronos-production-f584.up.railway.app/users'));

    if (response.statusCode == 200) {
      final List<dynamic> users = jsonDecode(response.body);

      setState(() {
        availableUsers = {
          for (var user in users)
            (user['_id']): {
              'name': user['nome'],
              'email': user['email'],
              'avatar': user['foto_url'] ?? '', // substitui 'avatar'
            }
        };
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Erro ao buscar usuários disponíveis: ${response.statusCode}')),
      );
    }
  }

  void addMember() async {
    if (selectedUserId != null && selectedRole != null) {
      final url = Uri.parse(
          'https://chronos-production-f584.up.railway.app/users/$selectedUserId/assign-to-project/${widget.projectId}');

      try {
        // MODIFICAR AQUI PARA ENVIAR O "papel" NO CORPO
        final response = await http.post(
          url,
          headers: {
            'Content-Type':
                'application/json; charset=UTF-8', // Adicionar header de content-type
          },
          body: jsonEncode(<String, String>{
            // Enviar o papel no corpo
            'papel': selectedRole!,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Ajustar para 200 ou 201
          await fetchProjectMembers();

          setState(() {
            selectedUserId = null;
            selectedRole = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Usuário adicionado ao projeto com sucesso!')),
          );
        } else {
          // Tentar decodificar a mensagem de erro do backend se houver
          String errorMessage =
              'Erro ao adicionar usuário: ${response.statusCode}';
          try {
            final responseBody = jsonDecode(response.body);
            if (responseBody['message'] != null) {
              errorMessage += ' - ${responseBody['message']}';
            }
          } catch (e) {
            // não faz nada se o corpo não for JSON
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro de rede ao tentar adicionar usuário: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, selecione um usuário e um papel.')),
      );
    }
  }

  void removeMember(int index) async {
    final userId = teamMembers[index]['id'];

    if (userId == null) {
      return;
    }

    final response = await http.delete(
      Uri.parse(
          'https://chronos-production-f584.up.railway.app/project/${widget.projectId}/remove-member/$userId'),
    );

    if (response.statusCode == 200) {
      fetchProjectMembers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membro removido com sucesso!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover membro')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAvailableUsers();
    fetchProjectMembers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Projeto ${widget.projectName}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Row(
        children: [
          // Adicionar Membro
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Adicionar Membro à Equipe",
                      style: TextStyle(fontSize: 20, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Selecione um usuário",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    availableUsers.isEmpty
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<String>(
                            value: selectedUserId,
                            items: availableUsers.entries.map((entry) {
                              final user = entry.value;
                              return DropdownMenuItem(
                                value: entry.key,
                                child: Text(user['name']!),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedUserId = value;
                              });
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[100],
                              hintText: 'Selecionar usuário',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                    const Text(
                      "Papel no projeto",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      items: const [
                        DropdownMenuItem(value: 'PO', child: Text("PO")),
                        DropdownMenuItem(value: 'Dev', child: Text("Dev")),
                        DropdownMenuItem(
                            value: 'Scrum Master', child: Text("Scrum Master")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        hintText: 'Selecionar papel',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: addMember,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.corPricipal,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text(
                        "Adicionar à Equipe",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lista de Membros
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Membros da Equipe",
                      style: TextStyle(fontSize: 20, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Expanded(
                            child: Text("Usuário",
                                style: TextStyle(color: Colors.black54))),
                        Expanded(
                            child: Text("Email",
                                style: TextStyle(color: Colors.black54))),
                        Expanded(
                            child: Text("Papel",
                                style: TextStyle(color: Colors.black54))),
                        SizedBox(width: 60),
                      ],
                    ),
                    const Divider(color: Colors.black26),
                    ...teamMembers.asMap().entries.map(
                      (entry) {
                        final i = entry.key;
                        final member = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.corPricipal,
                                      backgroundImage:
                                          NetworkImage(member['avatar']!),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      member['name']!,
                                      style: const TextStyle(
                                          color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      softWrap: false,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  member['email']!,
                                  style: const TextStyle(color: Colors.black54),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(member['role']!),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    member['role']!,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => removeMember(i),
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                              )
                            ],
                          ),
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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'PO':
        return Colors.grey[700]!;
      case 'Dev':
        return Colors.green[700]!;
      case 'Scrum Master':
        return Colors.purple[700]!;
      default:
        return Colors.blueGrey;
    }
  }
}
