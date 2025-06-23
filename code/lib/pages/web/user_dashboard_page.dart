import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:code/services/user_service.dart';
import 'package:code/models/user_model.dart';
import 'package:code/common/constants/app_colors.dart'; // Importe suas cores

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  final UserService _userService = UserService();
  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.getMyProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Dashboard de Desempenho'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[200],
      body: FutureBuilder<UserModel?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(
                child: Text('Não foi possível carregar os dados.'));
          }

          final user = snapshot.data!;
          final stats = user.statistics;

          // Envolve o conteúdo em um Center e ConstrainedBox para melhor layout em telas largas
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: 1100), // Largura máxima do conteúdo
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(user),
                    const SizedBox(height: 24),
                    Text(
                      'Suas Estatísticas',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      // **AJUSTE PRINCIPAL:** Aumentar a proporção torna os cards mais "baixos"
                      childAspectRatio: 1.8,
                      children: [
                        _buildStatCard(
                          icon: Icons.check_circle_outline,
                          label: 'Tarefas Concluídas',
                          value: stats.tarefasConcluidas.toString(),
                          color: Colors.green,
                        ),
                        _buildStatCard(
                          icon: Icons.star_border,
                          label: 'Média de Notas',
                          value: stats.mediaNotas.toStringAsFixed(1),
                          color: Colors.orange,
                        ),
                        _buildStatCard(
                          icon: Icons.control_point_duplicate,
                          label: 'Total de Pontos',
                          value: stats.totalPontosRecebidos.toString(),
                          color: Colors.blue,
                        ),
                        _buildStatCard(
                          icon: Icons.event,
                          label: 'Última Conclusão',
                          value: _formatDate(stats.ultimaConclusao),
                          color: Colors.purple,
                          isSmallText: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            backgroundImage:
                user.fotoUrl != null ? NetworkImage(user.fotoUrl!) : null,
            child: user.fotoUrl == null
                ? Text(
                    user.nome.isNotEmpty ? user.nome[0] : 'U',
                    style: TextStyle(fontSize: 30, color: AppColors.primary),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nome,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                      fontSize: 14, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Text("SCORE",
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(
                user.score.toString(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isSmallText = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmallText ? 18 : 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yy').format(date);
    } catch (e) {
      return 'Data inválida';
    }
  }
}
