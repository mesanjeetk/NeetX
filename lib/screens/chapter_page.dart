import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_viewer_page.dart';

class ChapterPage extends StatelessWidget {
  final String batchId, subjectId, chapterId, file, chapterName;
  const ChapterPage({super.key, required this.batchId, required this.subjectId, required this.chapterId, required this.file, required this.chapterName});

  Future<Map<String, dynamic>> fetchBatch() async {
    final res = await http.get(Uri.parse('https://mesanjeetk.github.io/NeetX-Data/$file'));
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to load');
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton(
                            child: const Text('View PDF'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => PDFViewerPage(url: l['pdf'])),
                              );
                            },
                          ),
                          ElevatedButton(
                            child: const Text('Open PDF Externally'),
                            onPressed: () async {
                              final uri = Uri.parse(l['pdf']);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
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
