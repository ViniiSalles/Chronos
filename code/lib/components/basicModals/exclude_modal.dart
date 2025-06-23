import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ExcludeModal extends StatelessWidget {
  final String itemId;
  final String type;
  const ExcludeModal({super.key, required this.type, required this.itemId,});

  
  void excludeTask(BuildContext context, id) async {
    final url =
        Uri.parse('https://chronos-production-f584.up.railway.app/tasks/$id');

    final response = await http.delete(url);

    if (response.statusCode == 200) {
      // Sucesso! Você pode processar os dados aqui.
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sucesso'),
          content: const Text('Task deletada com sucesso!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); 
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // Tratar erro
      print('Erro ao deletar task: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, Map<String, String>> textValues = {
      "Task": {
        "title": "Deseja realmente excluir esta tarefa?",
        "content":
            "Essa tarefa será excluida permanentemente, junto a todas as suas informações/relações no sistema. Deseja continuar?"
      },
      "Project": {
        "title": "Deseja realmente excluir este projeto?",
        "content":
            "Esse projeto será excluido permanentemente, junto a todas as suas informações/relações no sistema. Deseja continuar?"
      },
    };

    return AlertDialog(
      title: Text(textValues[type]!["title"]!),
      content: Text(textValues[type]!["content"]!),
      actions: <Widget>[
        TextButton(
          child: Text('Cancelar'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.red, // Define a cor de fundo
          ),
          child: Text(
            'Excluir',
            style: TextStyle(color: Colors.white), // Define a cor do texto
          ),
          onPressed: () {
            excludeTask(context, itemId);
          },
        ),
      ],
    );
  }
}
