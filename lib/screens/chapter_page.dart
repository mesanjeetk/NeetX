import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_viewer_page.dart';

class ChapterPage extends StatelessWidget {
  final String batchId, subjectId, chapterId, file, chapterName;
  const ChapterPage({
    super.key,
    required this.batchId,
    required this.subjectId,
    required this.chapterId,
    required this.file,
    required this.chapterName,
  });

  Future<Map<String, dynamic>> fetchBatch() async {
    final res = await http.get(Uri.parse('https://mesanjeetk.github.io/NeetX-Data/$file'));
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to load');
  }

  Future<void> _launchVideoUrl(BuildContext context, String rawUrl) async {
    if (rawUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No video URL available')),
      );
      return;
    }

    Uri? uri = Uri.tryParse(rawUrl);

    // If youtu.be short link, convert to full youtube.com link
    if (uri != null && uri.host == 'youtu.be') {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : '';
      uri = Uri.parse('https://www.youtube.com/watch?v=$id');
    }

    if (uri != null && await canLaunchUrl(uri)) {
      final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open video URL')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid video URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(chapterName)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchBatch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

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
                              final uri = Uri.tryParse(l['pdf']);
                              if (uri != null && await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not open PDF URL')),
                                );
                              }
                            },
                          ),
                          ElevatedButton(
                            child: const Text('View Video'),
                            onPressed: () async {
                              await _launchVideoUrl(context, l['video']);
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
