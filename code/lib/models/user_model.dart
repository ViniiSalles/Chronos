class UserModel {
  final String id;
  final String nome;
  final String email;
  final String? fotoUrl;
  final int score;
  final UserStatistics statistics;

  UserModel({
    required this.id,
    required this.nome,
    required this.email,
    this.fotoUrl,
    required this.score,
    required this.statistics,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      nome: json['nome'],
      email: json['email'],
      fotoUrl: json['foto_url'],
      score: json['score'] ?? 0,
      statistics: UserStatistics.fromJson(json['statistics'] ?? {}),
    );
  }
}

class UserStatistics {
  final int tarefasConcluidas;
  final double mediaNotas;
  final int totalPontosRecebidos;
  final String? ultimaConclusao; // String para facilitar a exibição

  UserStatistics({
    required this.tarefasConcluidas,
    required this.mediaNotas,
    required this.totalPontosRecebidos,
    this.ultimaConclusao,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      tarefasConcluidas: json['tarefasConcluidas'] ?? 0,
      // Garante que a nota seja double
      mediaNotas: (json['mediaNotas'] ?? 0).toDouble(),
      totalPontosRecebidos: json['totalPontosRecebidos'] ?? 0,
      ultimaConclusao: json['ultimaConclusao'],
    );
  }
}
