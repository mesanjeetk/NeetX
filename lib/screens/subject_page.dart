import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import '../widgets/gradient_card.dart';

class SubjectPage extends StatelessWidget {
  final String batchId, subjectId, file, subjectName;
  const SubjectPage({super.key, required this.batchId, required this.subjectId, required this.file, required this.subjectName});

  Future<Map<String, dynamic>> fetchBatch() async {
    final res = await http.get(Uri.parse('https://mesanjeetk.github.io/NeetX-Data/$file'));
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to load');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(subjectName)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchBatch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final chapters = snapshot.data!['subjects'][subjectId]['chapters'] as Map<String, dynamic>;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: chapters.entries.map((e) {
              final id = e.key;
              final chapterName = e.value['name'];
              return GradientCard(
                title: chapterName,
                onTap: () => context.push('/chapter/$batchId/$subjectId/$id?file=$file&name=$chapterName'),
                colors: [Colors.orange, Colors.deepOrange],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
