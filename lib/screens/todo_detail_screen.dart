import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';

class TodoDetailScreen extends StatefulWidget {
  final String todoId;

  const TodoDetailScreen({Key? key, required this.todoId}) : super(key: key);

  @override
  _TodoDetailScreenState createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  final _subtaskController = TextEditingController();
  Map<String, dynamic>? _todo;

  @override
  void initState() {
    super.initState();
    _loadTodo();
  }

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  void _loadTodo() {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    _todo = todoProvider.todos.firstWhere(
      (todo) => todo['_id'] == widget.todoId,
      orElse: () => {},
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_todo == null || _todo!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Todo Details'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Todo not found'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final isCompleted = _todo!['completed'] == true;
    final priority = _todo!['priority'] ?? 'medium';
    final dueDate = _todo!['dueDate'] != null ? DateTime.parse(_todo!['dueDate']) : null;
    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now()) && !isCompleted;
    final subtasks = _todo!['subtasks'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Todo Details'),
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditDialog();
                  break;
                case 'delete':
                  _showDeleteDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: theme.colorScheme.error),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          // Update local todo when provider changes
          final updatedTodo = todoProvider.todos.firstWhere(
            (todo) => todo['_id'] == widget.todoId,
            orElse: () => _todo!,
          );
          _todo = updatedTodo;

          return SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTodoHeader(theme),
                SizedBox(height: 24),
                _buildTodoDetails(theme),
                SizedBox(height: 24),
                _buildSubtasksSection(theme, subtasks),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodoHeader(ThemeData theme) {
    final isCompleted = _todo!['completed'] == true;
    final priority = _todo!['priority'] ?? 'medium';

    Color priorityColor;
    switch (priority) {
      case 'urgent':
        priorityColor = Colors.red;
        break;
      case 'high':
        priorityColor = Colors.orange;
        break;
      case 'medium':
        priorityColor = Colors.blue;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isCompleted,
                  onChanged: (value) {
                    Provider.of<TodoProvider>(context, listen: false)
                        .toggleTodo(_todo!['_id']);
                  },
                ),
                Expanded(
                  child: Text(
                    _todo!['title'],
                    style: theme.textTheme.headlineSmall?.copyWith(
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? Colors.grey : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: priorityColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (_todo!['description'] != null && _todo!['description'].isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                _todo!['description'],
                style: theme.textTheme.bodyLarge?.copyWith(
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? Colors.grey : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodoDetails(ThemeData theme) {
    final dueDate = _todo!['dueDate'] != null ? DateTime.parse(_todo!['dueDate']) : null;
    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now()) && _todo!['completed'] != true;
    final createdAt = DateTime.parse(_todo!['createdAt']);
    final updatedAt = DateTime.parse(_todo!['updatedAt']);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            if (_todo!['category'] != null && _todo!['category'].isNotEmpty)
              _buildDetailRow('Category', _todo!['category'], Icons.folder),
            if (dueDate != null)
              _buildDetailRow(
                'Due Date',
                DateFormat('MMM dd, yyyy').format(dueDate),
                Icons.schedule,
                isError: isOverdue,
              ),
            _buildDetailRow(
              'Created',
              DateFormat('MMM dd, yyyy').format(createdAt),
              Icons.calendar_today,
            ),
            _buildDetailRow(
              'Last Updated',
              DateFormat('MMM dd, yyyy').format(updatedAt),
              Icons.update,
            ),
            if (_todo!['tags'] != null && (_todo!['tags'] as List).isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                'Tags',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: (_todo!['tags'] as List).map<Widget>((tag) {
                  return Chip(
                    label: Text('#$tag'),
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {bool isError = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isError ? Colors.red : Colors.grey[600],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isError ? Colors.red : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtasksSection(ThemeData theme, List subtasks) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtasks (${subtasks.length})',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddSubtaskDialog,
                  icon: Icon(Icons.add),
                  label: Text('Add'),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (subtasks.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.task_alt, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No subtasks yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ...subtasks.map<Widget>((subtask) {
                final isCompleted = subtask['completed'] == true;
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Checkbox(
                      value: isCompleted,
                      onChanged: (value) {
                        Provider.of<TodoProvider>(context, listen: false)
                            .toggleSubtask(_todo!['_id'], subtask['_id']);
                      },
                    ),
                    title: Text(
                      subtask['title'],
                      style: TextStyle(
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? Colors.grey : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: theme.colorScheme.error),
                      onPressed: () => _showDeleteSubtaskDialog(subtask),
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    // TODO: Implement edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Todo'),
        content: Text('Are you sure you want to delete "${_todo!['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await Provider.of<TodoProvider>(context, listen: false)
                  .deleteTodo(_todo!['_id']);
              Navigator.pop(context);
              if (success) {
                context.go('/home');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Todo deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddSubtaskDialog() {
    _subtaskController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Subtask'),
        content: TextField(
          controller: _subtaskController,
          decoration: InputDecoration(
            labelText: 'Subtask title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_subtaskController.text.isNotEmpty) {
                final success = await Provider.of<TodoProvider>(context, listen: false)
                    .addSubtask(_todo!['_id'], _subtaskController.text);
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Subtask added')),
                  );
                }
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSubtaskDialog(Map<String, dynamic> subtask) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Subtask'),
        content: Text('Are you sure you want to delete "${subtask['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Implement delete subtask
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Delete subtask functionality coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}