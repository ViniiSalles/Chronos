import 'package:code/pages/web/create_meeting_form.dart';
import 'package:flutter/material.dart';
import 'package:code/common/constants/app_colors.dart';

class CreateMeetingPage extends StatelessWidget {
  const CreateMeetingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // <--- AQUI ESTÁ A CORREÇÃO PRINCIPAL: Adicione o Scaffold
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Criar Nova Reunião',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: CreateMeetingForm(
          onSuccess: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
