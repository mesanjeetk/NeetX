import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import '../widgets/gradient_card.dart';

class BatchPage extends StatelessWidget {
  final String batchId, file, name;
  const BatchPage({super.key, required this.batchId, required this.file, required this.name});

  Future<Map<String, dynamic>> fetchBatch() async {
    final res = await http.get(Uri.parse('https://mesanjeetk.github.io/NeetX-Data/$file'));
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to load');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchBatch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final subjects = snapshot.data!['subjects'] as Map<String, dynamic>;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: subjects.entries.map((e) {
              final id = e.key;
              final subjectName = e.value['name'];
              return GradientCard(
                title: subjectName,
                onTap: () => context.push('/subject/$batchId/$id?file=$file&name=$subjectName'),
                colors: [Colors.purple, Colors.deepPurple],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
