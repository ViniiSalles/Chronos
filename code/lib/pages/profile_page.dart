import 'package:flutter/material.dart';
import 'package:code/components/mobile_layout.dart';
import 'package:provider/provider.dart';
import 'package:code/common/providers/language_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Classe ApiService Simplificada (coloque em seu arquivo de serviço apropriado depois)
class ApiService {
  final String _baseUrl = "http://10.0.2.2:3000"; // Seu endereço de backend

  Future<http.Response> patch(
      String endpoint, Map<String, dynamic> data, String? token) async {
    final url = Uri.parse('$_baseUrl/$endpoint');

    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      return response;
    } catch (e) {
      print('Erro na chamada PATCH para $url: $e');
      throw Exception('Falha ao conectar ao servidor: ${e.toString()}');
    }
  }
}
// Fim da Classe ApiService Simplificada

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _securityFormKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _selectedLanguage;
  String? _selectedTimezone;

  final List<String> _languages = ['Português', 'English', 'Español'];
  final List<String> _timezones = [
    'GMT-3',
    'GMT-2',
    'GMT-1',
    'GMT',
    'GMT+1',
    'GMT+2'
  ];

  User? _currentUser;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _nameController.text = _currentUser!.displayName ?? '';
      _emailController.text = _currentUser!.email ?? '';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final languageProvider =
            Provider.of<LanguageProvider>(context, listen: false);
        setState(() {
          _selectedLanguage = languageProvider.currentLanguage;
          _selectedTimezone = languageProvider.currentTimezone;

          if (_selectedLanguage == null ||
              !_languages.contains(_selectedLanguage)) {
            _selectedLanguage = _languages.first;
          }
          if (_selectedTimezone == null ||
              !_timezones.contains(_selectedTimezone)) {
            _selectedTimezone = _timezones.firstWhere((tz) => tz == 'GMT-3',
                orElse: () => _timezones.first);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signOut(BuildContext context) async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Logout'),
          content: const Text('Você tem certeza que deseja sair?'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sair'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);

      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        print('SharedPreferences limpas.');

        await FirebaseAuth.instance.signOut();
        print('Logout do Firebase realizado.');

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/login', (Route<dynamic> route) => false);
        }
      } catch (e) {
        print('Erro durante o logout: $e');
        if (mounted) {
          // Mesmo que o isLoading seja true, se a navegação não ocorrer (raro, mas possível se signOut falhar e mounted ainda for true),
          // é bom resetar o isLoading no catch.
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erro ao fazer logout: ${e.toString()}',
                    style: const TextStyle(color: Colors.white)),
                backgroundColor: Colors.red),
          );
        }
      }
      // Se o logout for bem-sucedido e a navegação ocorrer, não precisamos mais definir _isLoading = false,
      // pois o widget será desmontado. Se a navegação falhar antes de ocorrer, o catch o manipula.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return isMobile ? _buildMobile(context) : _buildWeb(context);
  }

  Widget _buildWeb(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Row(
        children: [
          Container(
            width: 250,
            color: theme.colorScheme.primary,
            child: Column(
              children: [
                const SizedBox(height: 32),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.onPrimary,
                  backgroundImage: (_currentUser?.photoURL != null &&
                          _currentUser!.photoURL!.isNotEmpty)
                      ? NetworkImage(_currentUser!.photoURL!)
                      : null,
                  child: (_currentUser?.photoURL == null ||
                          _currentUser!.photoURL!.isEmpty)
                      ? Icon(Icons.person,
                          size: 60, color: theme.colorScheme.primary)
                      : null,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    _currentUser?.displayName ?? 'Usuário',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.onPrimary),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                _SidebarOption(
                  icon: Icons.account_circle,
                  label: 'Meu Perfil',
                  selected: _tabController.index == 0,
                  tooltip: 'Meu perfil',
                  onTap: () {
                    _tabController.animateTo(0);
                    setState(() {});
                  },
                ),
                _SidebarOption(
                  icon: Icons.security,
                  label: 'Segurança',
                  selected: _tabController.index == 1,
                  tooltip: 'Configurações de Segurança',
                  onTap: () {
                    _tabController.animateTo(1);
                    setState(() {});
                  },
                ),
                _SidebarOption(
                  icon: Icons.language,
                  label: 'Preferências',
                  selected: _tabController.index == 2,
                  tooltip: 'Tempo e Linguagem',
                  onTap: () {
                    _tabController.animateTo(2);
                    setState(() {});
                  },
                ),
                const Divider(
                    color: Colors.white30,
                    indent: 16,
                    endIndent: 16,
                    height: 32),
                _SidebarOption(
                  icon: Icons.logout,
                  label: 'Sair',
                  selected: false,
                  tooltip: 'Fazer logout',
                  onTap: _isLoading ? null : () => _signOut(context),
                  iconColor: theme
                      .colorScheme.errorContainer, // Usando cor de erro do tema
                  textColor: theme.colorScheme.errorContainer,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Copyright\n©${DateTime.now().year}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.7)),
                      textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Configurações do Perfil',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TabBar(
                    controller: _tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.textTheme.bodyMedium?.color,
                    indicatorColor: theme.colorScheme.primary,
                    indicatorWeight: 3,
                    onTap: (_) => setState(() {}),
                    tabs: const [
                      Tab(text: 'Geral'),
                      Tab(text: 'Segurança'),
                      Tab(text: 'Preferências'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGeneralTab(context, isMobile: false),
                        _buildSecurityTab(context, isMobile: false),
                        _buildRegionTab(context, isMobile: false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    final theme = Theme.of(context);
    return MobileLayout(
      title: 'Perfil',
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'Geral'),
              Tab(icon: Icon(Icons.security), text: 'Segurança'),
              Tab(icon: Icon(Icons.language), text: 'Preferências'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralTab(context, isMobile: true),
                _buildSecurityTab(context, isMobile: true),
                _buildRegionTab(context, isMobile: true),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 8, 16, 16), // Ajuste de padding
            child: ElevatedButton.icon(
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.logout),
              label: const Text('Sair'),
              onPressed: _isLoading ? null : () => _signOut(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error, // Cor de erro do tema
                foregroundColor: theme.colorScheme.onError,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTab(BuildContext context, {required bool isMobile}) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 24,
      ),
      child: Center(
        child: Form(
          key: _formKey,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Minha Foto', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: isMobile ? 50 : 70,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        backgroundImage: (_currentUser?.photoURL != null &&
                                _currentUser!.photoURL!.isNotEmpty)
                            ? NetworkImage(_currentUser!.photoURL!)
                            : null,
                        child: (_currentUser?.photoURL == null ||
                                _currentUser!.photoURL!.isEmpty)
                            ? Icon(Icons.person,
                                size: isMobile ? 60 : 80,
                                color: theme.colorScheme.onSurfaceVariant)
                            : null,
                      ),
                      IconButton.filled(
                        icon: const Icon(Icons.camera_alt, size: 20),
                        onPressed: _isLoading
                            ? null
                            : () {}, // _pickAndUploadImage, // Mantido comentado
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        tooltip: 'Alterar foto',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text('Detalhes da Conta', style: theme.textTheme.titleLarge),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nome',
                    hintText: 'Seu nome completo',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'O nome não pode estar vazio'
                      : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'seu@email.com',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  readOnly: true,
                  style: TextStyle(color: theme.disabledColor),
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ))
                        : const Icon(Icons.save_alt_outlined),
                    onPressed: _isLoading ? null : _updateGeneralProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      textStyle: theme.textTheme.labelLarge,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    label: const Text('Salvar Nome'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Future<void> _pickAndUploadImage() async {
  // Lógica de _pickAndUploadImage permanece comentada como no seu último código
  // }

  Widget _buildSecurityTab(BuildContext context, {required bool isMobile}) {
    final theme = Theme.of(context);
    return Form(
      key: _securityFormKey,
      child: SingleChildScrollView(
        padding:
            EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alterar Senha', style: theme.textTheme.titleLarge),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Nova Senha',
                    hintText: 'Mínimo 6 caracteres',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirme nova senha',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_person_outlined),
                  ),
                  validator: (value) {
                    if (_passwordController.text.isNotEmpty &&
                        (value == null || value.isEmpty)) {
                      return 'Confirme a nova senha';
                    }
                    if (_passwordController.text.isNotEmpty &&
                        value != _passwordController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_alt_outlined),
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_securityFormKey.currentState?.validate() ??
                                false) {
                              if (_passwordController.text.isNotEmpty) {
                                _updatePassword();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Digite a nova senha para alterá-la.')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      textStyle: theme.textTheme.labelLarge,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    label: const Text('Salvar Senha'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegionTab(BuildContext context, {required bool isMobile}) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: true);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding:
          EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preferências de Região', style: theme.textTheme.titleLarge),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedLanguage ?? languageProvider.currentLanguage,
                decoration: InputDecoration(
                  labelText: 'Linguagem',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.translate_outlined),
                ),
                items: _languages
                    .map((lang) => DropdownMenuItem(
                          value: lang,
                          child: Text(lang),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLanguage = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedTimezone ?? languageProvider.currentTimezone,
                decoration: InputDecoration(
                  labelText: 'Fuso horário',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.schedule_outlined),
                ),
                items: _timezones
                    .map((tz) => DropdownMenuItem(
                          value: tz,
                          child: Text(tz),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTimezone = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_alt_outlined),
                  onPressed: _isLoading ? null : _updatePreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    textStyle: theme.textTheme.labelLarge,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  label: const Text('Salvar Preferências'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateGeneralProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      User? user = _currentUser;
      if (user == null) throw Exception("Usuário não logado.");

      bool changed = false;
      if (user.displayName != _nameController.text) {
        await user.updateDisplayName(_nameController.text);
        _currentUser = FirebaseAuth.instance.currentUser;
        changed = true;
      }

      if (changed) {
        await _updateUserBackend({'nome': _nameController.text});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(changed
                  ? 'Nome atualizado com sucesso!'
                  : 'Nenhuma alteração no nome.'),
              backgroundColor: changed ? Colors.green : Colors.orange),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no Firebase Auth: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar perfil: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    setState(() => _isLoading = true);
    try {
      await _currentUser?.updatePassword(_passwordController.text);
      _passwordController.clear();
      _confirmPasswordController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Senha atualizada com sucesso!'),
              backgroundColor: Colors.green),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'Erro ao atualizar senha: ${e.message}';
        if (e.code == 'requires-recent-login') {
          errorMessage =
              'Esta operação é sensível e requer autenticação recente. Por favor, faça login novamente e tente de novo.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro inesperado: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserBackend(Map<String, dynamic> data) async {
    final firebaseUid = _currentUser?.uid;
    if (firebaseUid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erro: UID do Firebase não encontrado.')),
        );
      }
      throw Exception(
          "UID do Firebase não encontrado para atualização no backend.");
    }

    String? firebaseIdToken;
    try {
      firebaseIdToken = await _currentUser?.getIdToken();
      if (firebaseIdToken == null) {
        throw Exception(
            'Não foi possível obter o token de autenticação do Firebase.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao obter token Firebase: ${e.toString()}')),
        );
      }
      throw Exception('Erro ao obter token Firebase: ${e.toString()}');
    }

    final String endpoint = 'users/by-firebase/$firebaseUid';
    print("Enviando para backend ($endpoint): $data");

    try {
      final response = await _apiService.patch(
        endpoint,
        data,
        firebaseIdToken,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print(
            'Dados do usuário atualizados no backend com sucesso: ${response.body}');
      } else {
        print(
            'Falha ao atualizar dados no backend: ${response.statusCode} ${response.body}');
        throw Exception(
            'Falha ao sincronizar com o servidor (backend). Código: ${response.statusCode}, Resposta: ${response.body}');
      }
    } catch (e) {
      print('Erro na chamada _updateUserBackend: $e');
      throw Exception('Falha ao comunicar com o servidor: ${e.toString()}');
    }
  }

  Future<void> _updatePreferences() async {
    setState(() => _isLoading = true);
    try {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);

      bool changed = false;
      Map<String, dynamic> preferencesData = {};

      if (_selectedLanguage != null &&
          _selectedLanguage != languageProvider.currentLanguage) {
        languageProvider.changeLanguage(_selectedLanguage!);
        preferencesData['idioma'] = _selectedLanguage;
        changed = true;
      }
      if (_selectedTimezone != null &&
          _selectedTimezone != languageProvider.currentTimezone) {
        languageProvider.changeTimezone(_selectedTimezone!);
        preferencesData['fusoHorario'] = _selectedTimezone;
        changed = true;
      }

      if (changed && preferencesData.isNotEmpty) {
        await _updateUserBackend(preferencesData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(changed
                  ? 'Preferências salvas com sucesso!'
                  : 'Nenhuma preferência foi alterada.'),
              backgroundColor: changed ? Colors.green : Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar preferências: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _SidebarOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final String? tooltip;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;

  const _SidebarOption({
    required this.icon,
    required this.label,
    required this.selected,
    this.tooltip,
    this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ??
        (selected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onPrimary.withOpacity(0.7));
    final effectiveTextColor = textColor ??
        (selected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onPrimary.withOpacity(0.7));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: theme.colorScheme.onPrimary.withOpacity(0.1),
        highlightColor: theme.colorScheme.onPrimary.withOpacity(0.2),
        splashColor: theme.colorScheme.onPrimary.withOpacity(0.15),
        child: Tooltip(
          message: tooltip ?? label,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: effectiveIconColor, size: 22),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: effectiveTextColor,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
