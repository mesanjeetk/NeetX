import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/batch/:batchId', builder: (context, state) {
      final batchId = state.pathParameters['batchId']!;
      final file = state.uri.queryParameters['file']!;
      final name = state.uri.queryParameters['name']!;
      return BatchPage(batchId: batchId, file: file, name: name);
    }),
    GoRoute(path: '/subject/:batchId/:subjectId', builder: (context, state) {
      final batchId = state.pathParameters['batchId']!;
      final subjectId = state.pathParameters['subjectId']!;
      final file = state.uri.queryParameters['file']!;
      final subjectName = state.uri.queryParameters['name']!;
      return SubjectPage(batchId: batchId, file: file, subjectId: subjectId, subjectName: subjectName);
    }),
    GoRoute(path: '/chapter/:batchId/:subjectId/:chapterId', builder: (context, state) {
      final batchId = state.pathParameters['batchId']!;
      final subjectId = state.pathParameters['subjectId']!;
      final chapterId = state.pathParameters['chapterId']!;
      final file = state.uri.queryParameters['file']!;
      final chapterName = state.uri.queryParameters['name']!;
      return ChapterPage(batchId: batchId, file: file, subjectId: subjectId, chapterId: chapterId, chapterName: chapterName);
    }),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'Study Batches',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  Future<Map<String, dynamic>> fetchBatches() async {
    final response = await http.get(Uri.parse('https://mesanjeetk.github.io/NeetX-Data/batches.json'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load batches');
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
              return Card(
                child: ListTile(
                  title: Text(name),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => context.go('/batch/$id?file=$file&name=$name'),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class BatchPage extends StatelessWidget {
  final String batchId, file, name;
  const BatchPage({super.key, required this.batchId, required this.file, required this.name});
  Future<Map<String, dynamic>> fetchBatch() async {
    final res = await http.get(Uri.parse('https://mesanjeetk.github.io/NeetX-Data/$file'));
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to load batch');
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
              return Card(
                child: ListTile(
                  title: Text(subjectName),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => context.go('/subject/$batchId/$id?file=$file&name=$subjectName'),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class SubjectPage extends StatelessWidget {
  final String batchId, subjectId, file, subjectName;
  const SubjectPage({super.key, required this.batchId, required this.subjectId, required this.file, required this.subjectName});
  Future<Map<String, dynamic>> fetchBatch() async {
    final res = await http.get(Uri.parse('https://mesanjeetk.github.io/NeetX-Data/$file'));
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to load batch');
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
              return Card(
                child: ListTile(
                  title: Text(chapterName),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => context.go('/chapter/$batchId/$subjectId/$id?file=$file&name=$chapterName'),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class ChapterPage extends StatelessWidget {
  final String batchId, subjectId, chapterId, file, chapterName;
  const ChapterPage({super.key, required this.batchId, required this.subjectId, required this.chapterId, required this.file, required this.chapterName});
  Future<Map<String, dynamic>> fetchBatch() async {
    final res = await http.get(Uri.parse('https://mesanjeetk.github.io/NeetX-Data/$file'));
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to load batch');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(chapterName)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchBatch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final lectures = snapshot.data!['subjects'][subjectId]['chapters'][chapterId]['lectures'] as Map<String, dynamic>;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: lectures.entries.map((e) {
              final l = e.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Duration: ${l['duration']} | Teacher: ${l['teacher']}'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            child: const Text('View PDF'),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => PDFViewerPage(url: l['pdf'])));
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            child: const Text('Open PDF Externally'),
                            onPressed: () async {
                              final uri = Uri.parse(l['pdf']);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            child: const Text('View Video'),
                            onPressed: () async {
                              final uri = Uri.parse(l['video']);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class PDFViewerPage extends StatelessWidget {
  final String url;
  const PDFViewerPage({super.key, required this.url});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Viewer')),
      body: SfPdfViewer.network(url),
    );
  }
}
