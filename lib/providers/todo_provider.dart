import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_provider.dart';

class TodoProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _todos = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _error;
  AuthProvider? _authProvider;

  static const String _baseUrl = 'http://localhost:3000/api';

  // Getters
  List<Map<String, dynamic>> get todos => _todos;
  List<Map<String, dynamic>> get completedTodos => 
      _todos.where((todo) => todo['completed'] == true).toList();
  List<Map<String, dynamic>> get pendingTodos => 
      _todos.where((todo) => todo['completed'] == false).toList();
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  Future<void> fetchTodos({
    int page = 1,
    int limit = 50,
    String? search,
    String? priority,
    String? category,
    bool? completed,
  }) async {
    if (_authProvider?.token == null) return;

    _setLoading(true);
    _clearError();

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sort': '-createdAt',
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (priority != null) queryParams['priority'] = priority;
      if (category != null) queryParams['category'] = category;
      if (completed != null) queryParams['completed'] = completed.toString();

      final uri = Uri.parse('$_baseUrl/todos').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${_authProvider!.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _todos = List<Map<String, dynamic>>.from(data['data']['todos']);
      } else {
        final errorData = json.decode(response.body);
        _setError(errorData['message'] ?? 'Failed to fetch todos');
      }
    } catch (e) {
      _setError('Network error. Please check your connection.');
    }

    _setLoading(false);
  }

  Future<void> fetchStats() async {
    if (_authProvider?.token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/todos/stats'),
        headers: {'Authorization': 'Bearer ${_authProvider!.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _stats = data['data'];
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently for stats
    }
  }

  Future<bool> addTodo({
    required String title,
    String? description,
    String priority = 'medium',
    String? category,
    DateTime? dueDate,
    List<String>? tags,
  }) async {
    if (_authProvider?.token == null) return false;

    _clearError();

    try {
      final todoData = {
        'title': title,
        'priority': priority,
        if (description != null && description.isNotEmpty) 'description': description,
        if (category != null && category.isNotEmpty) 'category': category,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
        if (tags != null && tags.isNotEmpty) 'tags': tags,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/todos'),
        headers: {
          'Authorization': 'Bearer ${_authProvider!.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode(todoData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _todos.insert(0, data['data']['todo']);
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        _setError(errorData['message'] ?? 'Failed to add todo');
      }
    } catch (e) {
      _setError('Network error. Please try again.');
    }
    return false;
  }

  Future<bool> updateTodo(String id, Map<String, dynamic> updates) async {
    if (_authProvider?.token == null) return false;

    _clearError();

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/todos/$id'),
        headers: {
          'Authorization': 'Bearer ${_authProvider!.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updatedTodo = data['data']['todo'];
        final index = _todos.indexWhere((todo) => todo['_id'] == id);
        if (index != -1) {
          _todos[index] = updatedTodo;
          notifyListeners();
        }
        return true;
      } else {
        final errorData = json.decode(response.body);
        _setError(errorData['message'] ?? 'Failed to update todo');
      }
    } catch (e) {
      _setError('Network error. Please try again.');
    }
    return false;
  }

  Future<bool> toggleTodo(String id) async {
    if (_authProvider?.token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/todos/$id/toggle'),
        headers: {'Authorization': 'Bearer ${_authProvider!.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updatedTodo = data['data']['todo'];
        final index = _todos.indexWhere((todo) => todo['_id'] == id);
        if (index != -1) {
          _todos[index] = updatedTodo;
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      _setError('Failed to toggle todo');
    }
    return false;
  }

  Future<bool> deleteTodo(String id) async {
    if (_authProvider?.token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/todos/$id'),
        headers: {'Authorization': 'Bearer ${_authProvider!.token}'},
      );

      if (response.statusCode == 200) {
        _todos.removeWhere((todo) => todo['_id'] == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Failed to delete todo');
    }
    return false;
  }

  Future<bool> addSubtask(String todoId, String title) async {
    if (_authProvider?.token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/todos/$todoId/subtasks'),
        headers: {
          'Authorization': 'Bearer ${_authProvider!.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'title': title}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final updatedTodo = data['data']['todo'];
        final index = _todos.indexWhere((todo) => todo['_id'] == todoId);
        if (index != -1) {
          _todos[index] = updatedTodo;
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      _setError('Failed to add subtask');
    }
    return false;
  }

  Future<bool> toggleSubtask(String todoId, String subtaskId) async {
    if (_authProvider?.token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/todos/$todoId/subtasks/$subtaskId/toggle'),
        headers: {'Authorization': 'Bearer ${_authProvider!.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updatedTodo = data['data']['todo'];
        final index = _todos.indexWhere((todo) => todo['_id'] == todoId);
        if (index != -1) {
          _todos[index] = updatedTodo;
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      _setError('Failed to toggle subtask');
    }
    return false;
  }

  Future<bool> bulkComplete(List<String> todoIds) async {
    if (_authProvider?.token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/todos/bulk/complete'),
        headers: {
          'Authorization': 'Bearer ${_authProvider!.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'todoIds': todoIds}),
      );

      if (response.statusCode == 200) {
        // Refresh todos after bulk operation
        await fetchTodos();
        return true;
      }
    } catch (e) {
      _setError('Failed to complete todos');
    }
    return false;
  }

  Future<bool> bulkDelete(List<String> todoIds) async {
    if (_authProvider?.token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/todos/bulk/delete'),
        headers: {
          'Authorization': 'Bearer ${_authProvider!.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'todoIds': todoIds}),
      );

      if (response.statusCode == 200) {
        // Remove deleted todos from local list
        _todos.removeWhere((todo) => todoIds.contains(todo['_id']));
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Failed to delete todos');
    }
    return false;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() => _clearError();
}