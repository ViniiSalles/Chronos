import 'package:code/common/constants/firebase_options.dart';
import 'package:code/pages/notification_mobile_page.dart';
import 'package:code/pages/web/agenda_page.dart';
import 'package:code/pages/web/home_page.dart'; // Importe a HomePage
import 'package:code/pages/project_list_page.dart';
import 'package:code/pages/project_registration_page.dart';
import 'package:code/pages/project_list_mobile_page.dart';
import 'package:code/pages/task_list_mobile_page.dart';
import 'package:code/pages/settings_page.dart';
import 'package:code/pages/profile_page.dart';
import 'package:code/pages/login_page.dart';
import 'package:code/pages/web/burndown_chart_page.dart';

import 'package:code/common/providers/theme_provider.dart';
import 'package:code/common/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userUID = prefs.getString('userUID');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: ChronosApp(isUserLoggedIn: userUID != null, userUID: userUID),
    ),
  );
}

class ChronosApp extends StatelessWidget {
  final bool isUserLoggedIn;
  final String? userUID;

  const ChronosApp({super.key, required this.isUserLoggedIn, this.userUID});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Chronos',
          theme: themeProvider.theme,
          locale: languageProvider.currentLocale,
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('en', 'US'),
            Locale('es', 'ES'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: isUserLoggedIn
              ? _getInitialLoggedInScreen(context)
              : const LoginPage(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/projects': (context) {
              final shortestSide = MediaQuery.of(context).size.shortestSide;
              if (shortestSide < 600) {
                return const ProjectListMobilePage();
              } else {
                return const ProjectListPage();
              }
            },
            '/project-registration': (context) =>
                const ProjectRegistrationPage(),
            // Re-adicionando a rota '/home-page'
            '/home-page': (context) {
              final shortestSide = MediaQuery.of(context).size.shortestSide;
              if (shortestSide < 600) {
                return const ProjectListMobilePage();
              } else {
                return const HomePage(); // Apontando para a HomePage (Web/Desktop)
              }
            },
            '/tasks': (context) => const TaskListMobilePage(),
            '/profile': (context) => const ProfilePage(),
            '/settings': (context) => const SettingsPage(),
            '/notifications-mobile': (context) =>
                const NotificationMobilePage(),
            '/agenda': (context) => const AgendaPage()
          },
          onGenerateRoute: (RouteSettings settings) {
            WidgetBuilder builder;
            switch (settings.name) {
              case '/burndown-chart':
                final args = settings.arguments as Map<String, dynamic>?;
                if (args != null &&
                    args.containsKey('projectId') &&
                    args.containsKey('queryStartDate')) {
                  builder = (BuildContext _) => BurndownChartPage(
                        projectId: args['projectId'] as String,
                        queryStartDate: args['queryStartDate'] as DateTime,
                        queryEndDate: args['queryEndDate'] as DateTime,
                      );
                } else {
                  builder = (BuildContext _) => const Scaffold(
                        body: Center(
                          child: Text(
                              'Erro: Argumentos faltando para /burndown-chart'),
                        ),
                      );
                }
                break;
              default:
                builder = (BuildContext _) => Scaffold(
                      body: Center(
                        child: Text('Rota não encontrada: ${settings.name}'),
                      ),
                    );
            }
            return MaterialPageRoute(builder: builder, settings: settings);
          },
        );
      },
    );
  }
}

// A classe 'Home' que você tinha, mas que não está mais sendo usada diretamente como a "home" principal.
// Você pode remover esta classe se ela não for utilizada em outro lugar.
class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chronos')),
      body: const Center(child: Text('Welcome to Chronos!')),
    );
  }
}

// Função auxiliar para determinar a tela inicial correta após o login
Widget _getInitialLoggedInScreen(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        // Limite para mobile
        return const ProjectListMobilePage(); // Sua tela principal para mobile
      } else {
        return const HomePage(); // Sua tela principal para web/desktop
      }
    },
  );
}
