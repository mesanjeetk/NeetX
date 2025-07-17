import 'package:go_router/go_router.dart';
import 'screens/home_page.dart';
import 'screens/batch_page.dart';
import 'screens/subject_page.dart';
import 'screens/chapter_page.dart';

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
