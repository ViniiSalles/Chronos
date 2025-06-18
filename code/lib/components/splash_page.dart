import 'package:code/common/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // _navigateToLogin();
  }

  // void _navigateToLogin() {
  //   Future.delayed(const Duration(seconds: 3), () {
  //     Navigator.of(context).pushReplacement(
  //       MaterialPageRoute(builder: (context) => const LoginPage()),
  //     );
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
            colors: [AppColors.corPricipal, AppColors.corSegundaria],
          ),
        ),
        child: kIsWeb 
          ? _buildWebLayout() 
          : _buildMobileLayout(), 
      ),
    );
  }

  Widget _buildWebLayout() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Chronos",
          style: TextStyle(
            fontSize: 70.0,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 20),
        Text(
          "Sistema de Gestão de Tempo",
          style: TextStyle(
            fontSize: 24.0,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Chronos",
          style: TextStyle(
            fontSize: 50.0,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 10),
        Text(
          "Sistema de Gestão de Tempo",
          style: TextStyle(
            fontSize: 18.0,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
} 