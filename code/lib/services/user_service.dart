import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:code/models/user_model.dart'; // Você precisará criar este modelo

class UserService {
  static Future<String?> _getToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await user.getIdToken();
      return token;
    }
    print('ProjectService: Usuário não autenticado.');
    return null;
  }

  /// Busca os dados e estatísticas do usuário logado.
  Future<UserModel?> getMyProfile() async {
    final String? token = await _getToken();
    if (token == null) {
      print(
          'ProjectService (getProjectById): Token de autenticação não encontrado.');
      return null;
    }

    Uri url =
        Uri.parse('https://chronos-production-f584.up.railway.app/users/me');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        // Converte o JSON recebido para o nosso modelo de usuário.
        return UserModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Erro ao buscar perfil do usuário: $e');
      return null;
    }
  }
}
