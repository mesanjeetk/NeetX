import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import '../widgets/gradient_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<Map<String, dynamic>> fetchBatches() async {
    final res = await http.get(Uri.parse('https://mesanjeetk.github.io/NeetX-Data/batches.json'));
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to load');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Batches')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchBatches(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final batches = snapshot.data!['batches'] as Map<String, dynamic>;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: batches.entries.map((e) {
              final id = e.key;
              final name = e.value['name'];
              final file = e.value['file'];
              return GradientCard(
                title: name,
                onTap: () => context.push('/batch/$id?file=$file&name=$name'),
                colors: [Colors.indigo, Colors.blue],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
