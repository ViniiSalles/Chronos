import 'package:flutter/material.dart';
import 'package:code/common/constants/app_colors.dart'; // Certifique-se que este caminho está correto
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 1. Importar SharedPreferences

// Idealmente, mova esta URL para um arquivo de configuração/constantes
const String backendAuthUrl =
    'https://chronos-production-f584.up.railway.app/auth';

enum AuthMode { signUp, signIn }

class AuthForm extends StatefulWidget {
  const AuthForm({super.key});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  AuthMode _authMode = AuthMode.signIn;
  final Map<String, String> _authData = {
    'email': '',
    'password': '',
    // 'confirmPassword': '', // confirmPassword não precisa ser armazenado em _authData
    // já que sua validação é feita diretamente.
  };

  bool _isSignin() => _authMode == AuthMode.signIn;
  bool _isSignup() => _authMode == AuthMode.signUp;

  // 2. Adicionar dispose para o controller
  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _switchAuthMode() {
    setState(() {
      _authMode = _isSignin() ? AuthMode.signUp : AuthMode.signIn;
    });
  }

  Future<void> _saveSession(String uid) async {
    // Função auxiliar para salvar sessão
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userUID', uid);
    } catch (e) {
      print('Erro ao salvar sessão no SharedPreferences: $e');
      // Considere mostrar um feedback para o usuário se o salvamento da sessão local falhar,
      // embora o login no Firebase e backend possam ter sido bem-sucedidos.
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isLoading = true;
    });

    _formKey.currentState?.save();

    try {
      UserCredential userCredential;
      User? user;

      if (_isSignin()) {
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _authData['email']!,
          password: _authData['password']!,
        );
      } else {
        userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _authData['email']!,
          password: _authData['password']!,
        );
      }

      user = userCredential.user;
      if (user == null) {
        throw Exception('Usuário do Firebase não encontrado após a operação.');
      }

      final idToken = await user.getIdToken();
      if (idToken == null) {
        throw Exception('Falha ao obter token de ID do Firebase.');
      }

      // Enviar token ao backend NestJS
      final response = await http.post(
        Uri.parse(backendAuthUrl), // Usando a constante
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        // Opcional: Enviar algum corpo se o seu backend /auth esperar
        // body: jsonEncode({'email': user.email, 'uid': user.uid}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Sucesso (200, 201, etc.)
        // 3. Salvar UID no SharedPreferences após sucesso no backend
        await _saveSession(user.uid);

        if (mounted) {
          final shortestSide = MediaQuery.of(context).size.shortestSide;
          Navigator.of(context).pushReplacementNamed(
            shortestSide < 600 ? '/projects' : '/home-page',
          );
        }
      } else {
        // Erro vindo do backend
        _showErrorSnackBar(
            'Erro no servidor: ${response.statusCode}. Detalhes: ${response.body}');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Ocorreu um erro. Tente novamente.';
      if (e.code == 'email-already-in-use') {
        message = 'Este e-mail já está em uso.';
      } else if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        // Agrupado 'invalid-credential' com 'user-not-found' e 'wrong-password' para login
        message = 'E-mail ou senha incorretos.';
      } else if (e.code == 'invalid-email') {
        message = 'O formato do e-mail é inválido.';
      } else if (e.code == 'weak-password') {
        message = 'A senha é muito fraca.';
      }
      _showErrorSnackBar(message);
      print('FirebaseAuthException: ${e.code} - ${e.message}');
    } catch (e) {
      _showErrorSnackBar('Erro inesperado: $e');
      print('Erro geral: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;

    return Container(
      // Seu código de UI permanece o mesmo...
      // Apenas um exemplo de como ele continua:
      height: screenSize.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors
                .white, // Considere usar Theme.of(context).shadowColor ou similar
            blurRadius: 300,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 400),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            //Title
            Text(
              _isSignin() ? "Entrar" : "Registrar", // Título dinâmico
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors
                    .black54, // Considere usar Theme.of(context).textTheme
              ),
            ),

            Column(
              children: [
                //Email
                TextFormField(
                  onSaved: (email) => _authData['email'] = email?.trim() ?? "",
                  validator: (value) {
                    // Validação para ambos os modos
                    final email = value?.trim() ?? "";
                    if (email.isEmpty || !email.contains("@")) {
                      return "Informe um e-mail válido!";
                    }
                    return null;
                  },
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: const TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.black54),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.black54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.corPricipal),
                    ),
                    prefixIcon: Icon(Icons.email, color: AppColors.corPricipal),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                //Password
                TextFormField(
                  onSaved: (password) => _authData['password'] = password ?? "",
                  validator: (value) {
                    // Validação para ambos os modos
                    final password = value ?? "";
                    if (password.isEmpty ||
                        (_isSignup() && password.length < 6)) {
                      // Para login, apenas verificamos se não está vazio.
                      // Para signup, exigimos no mínimo 6 caracteres.
                      return _isSignup()
                          ? "A senha deve ter pelo menos 6 caracteres!"
                          : "Informe sua senha!";
                    }
                    return null;
                  },
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: "Senha",
                    labelStyle: const TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.black54),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.black54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.corPricipal),
                    ),
                    prefixIcon: Icon(Icons.lock, color: AppColors.corPricipal),
                  ),
                ),
                const SizedBox(height: 16),

                //Confirm Password
                if (_isSignup())
                  TextFormField(
                    // Não precisa de onSaved, pois não é usado em _authData diretamente para o submit
                    validator: (value) {
                      // Validação apenas para signup
                      final confirmPassword = value ?? "";
                      if (confirmPassword != _passwordController.text) {
                        return "As senhas não coincidem!";
                      }
                      return null;
                    },
                    obscureText: true,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: "Confirmar Senha",
                      labelStyle: const TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black54),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.corPricipal),
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: AppColors.corPricipal,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity, // Botão sempre com largura total
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                          color: AppColors.corPricipal,
                        ))
                      : ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.corPricipal,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: const TextStyle(
                                // Estilo do texto do botão
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              )),
                          child: Text(
                            _isSignup() ? "Registrar" : "Entrar",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                ),
              ],
            ),

            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignin() ? "Não tem uma conta?" : "Já tem uma conta?",
                      style: const TextStyle(color: Colors.black54),
                    ),
                    TextButton(
                      onPressed: _switchAuthMode,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4), // Padding menor
                        minimumSize: Size.zero, // Para remover padding extra
                        tapTargetSize: MaterialTapTargetSize
                            .shrinkWrap, // Para remover padding extra
                      ),
                      child: Text(
                        _isSignin() ? "Registrar" : "Entrar",
                        style: TextStyle(
                            color: AppColors.corPricipal,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (_isSignin())
                  TextButton(
                    onPressed: () {
                      // TODO: Implementar lógica de "Esqueceu a senha"
                      // Ex: FirebaseAuth.instance.sendPasswordResetEmail(email: _authData['email']!)
                      if (_authData['email']!.trim().isEmpty ||
                          !_authData['email']!.trim().contains('@')) {
                        _showErrorSnackBar(
                            'Por favor, insira seu e-mail para redefinir a senha.');
                        return;
                      }
                      try {
                        FirebaseAuth.instance.sendPasswordResetEmail(
                            email: _authData['email']!.trim());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'E-mail de redefinição de senha enviado para ${_authData['email']!}.')),
                        );
                      } catch (e) {
                        _showErrorSnackBar(
                            'Erro ao enviar e-mail de redefinição.');
                      }
                    },
                    child: Text(
                      "Esqueceu sua senha?",
                      style: TextStyle(color: AppColors.corPricipal),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
