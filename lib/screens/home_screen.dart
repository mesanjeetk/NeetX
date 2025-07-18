import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/todo_provider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  
  String _selectedPriority = 'medium';
  String _filterPriority = 'all';
  bool _showCompleted = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    await Future.wait([
      todoProvider.fetchTodos(),
      todoProvider.fetchStats(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Todo App'),
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'filter':
                  _showFilterDialog();
                  break;
                case 'profile':
                  context.push('/profile');
                  break;
                case 'logout':
                  _showLogoutDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list),
                    SizedBox(width: 8),
                    Text('Filter'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: theme.colorScheme.error),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: theme.colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatsCard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodoList(null),
                _buildTodoList(false),
                _buildTodoList(true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTodoDialog,
        icon: Icon(Icons.add),
        label: Text('Add Todo'),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final stats = todoProvider.stats?['overview'];
        if (stats == null) return SizedBox.shrink();

        return Container(
          margin: EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total', stats['total']?.toString() ?? '0', Icons.list),
                  _buildStatItem('Pending', stats['pending']?.toString() ?? '0', Icons.pending_actions),
                  _buildStatItem('Completed', stats['completed']?.toString() ?? '0', Icons.check_circle),
                  _buildStatItem('Overdue', stats['overdue']?.toString() ?? '0', Icons.warning),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTodoList(bool? completed) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        if (todoProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (todoProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(todoProvider.error!),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        List<Map<String, dynamic>> todos;
        if (completed == null) {
          todos = todoProvider.todos;
        } else if (completed) {
          todos = todoProvider.completedTodos;
        } else {
          todos = todoProvider.pendingTodos;
        }

        if (todos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  completed == null 
                      ? 'No todos yet'
                      : completed 
                          ? 'No completed todos'
                          : 'No pending todos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                Text(
                  'Tap the + button to add a new todo',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return _buildTodoCard(todo);
            },
          ),
        );
      },
    );
  }

  Widget _buildTodoCard(Map<String, dynamic> todo) {
    final theme = Theme.of(context);
    final isCompleted = todo['completed'] == true;
    final priority = todo['priority'] ?? 'medium';
    final dueDate = todo['dueDate'] != null ? DateTime.parse(todo['dueDate']) : null;
    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now()) && !isCompleted;

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
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/todo/${todo['_id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isCompleted,
                    onChanged: (value) {
                      Provider.of<TodoProvider>(context, listen: false)
                          .toggleTodo(todo['_id']);
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo['title'],
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? Colors.grey : null,
                          ),
                        ),
                        if (todo['description'] != null && todo['description'].isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              todo['description'],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: priorityColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      priority.toUpperCase(),
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditTodoDialog(todo);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(todo);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: theme.colorScheme.error),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (dueDate != null || todo['category'] != null || (todo['tags'] != null && todo['tags'].isNotEmpty))
                Padding(
                  padding: EdgeInsets.only(left: 48, top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (dueDate != null)
                        Chip(
                          label: Text(
                            DateFormat('MMM dd').format(dueDate),
                            style: TextStyle(fontSize: 12),
                          ),
                          backgroundColor: isOverdue ? Colors.red.withOpacity(0.1) : null,
                          side: BorderSide(
                            color: isOverdue ? Colors.red : Colors.grey.withOpacity(0.3),
                          ),
                          avatar: Icon(
                            Icons.schedule,
                            size: 16,
                            color: isOverdue ? Colors.red : Colors.grey,
                          ),
                        ),
                      if (todo['category'] != null && todo['category'].isNotEmpty)
                        Chip(
                          label: Text(
                            todo['category'],
                            style: TextStyle(fontSize: 12),
                          ),
                          avatar: Icon(Icons.folder, size: 16),
                        ),
                      if (todo['tags'] != null)
                        ...List<Widget>.from(
                          (todo['tags'] as List).take(2).map(
                            (tag) => Chip(
                              label: Text(
                                '#$tag',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTodoDialog() {
    _titleController.clear();
    _descriptionController.clear();
    _categoryController.clear();
    _selectedPriority = 'medium';

    showDialog(
      context: context,
      builder: (context) => _buildTodoDialog(
        title: 'Add New Todo',
        onSave: () async {
          if (_titleController.text.isNotEmpty) {
            final success = await Provider.of<TodoProvider>(context, listen: false).addTodo(
              title: _titleController.text,
              description: _descriptionController.text,
              priority: _selectedPriority,
              category: _categoryController.text,
            );
            if (success) Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showEditTodoDialog(Map<String, dynamic> todo) {
    _titleController.text = todo['title'] ?? '';
    _descriptionController.text = todo['description'] ?? '';
    _categoryController.text = todo['category'] ?? '';
    _selectedPriority = todo['priority'] ?? 'medium';

    showDialog(
      context: context,
      builder: (context) => _buildTodoDialog(
        title: 'Edit Todo',
        onSave: () async {
          if (_titleController.text.isNotEmpty) {
            final success = await Provider.of<TodoProvider>(context, listen: false).updateTodo(
              todo['_id'],
              {
                'title': _titleController.text,
                'description': _descriptionController.text,
                'priority': _selectedPriority,
                'category': _categoryController.text,
              },
            );
            if (success) Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildTodoDialog({required String title, required VoidCallback onSave}) {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: onSave,
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Todo'),
        content: Text('Are you sure you want to delete "${todo['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await Provider.of<TodoProvider>(context, listen: false)
                  .deleteTodo(todo['_id']);
              Navigator.pop(context);
              if (success) {
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

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Todos'),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Enter search term...',
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
            onPressed: () {
              Provider.of<TodoProvider>(context, listen: false)
                  .fetchTodos(search: _searchController.text);
              Navigator.pop(context);
            },
            child: Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Filter Todos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _filterPriority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterPriority = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              CheckboxListTile(
                title: Text('Show Completed'),
                value: _showCompleted,
                onChanged: (value) {
                  setState(() {
                    _showCompleted = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<TodoProvider>(context, listen: false).fetchTodos(
                  priority: _filterPriority == 'all' ? null : _filterPriority,
                  completed: _showCompleted ? null : false,
                );
                Navigator.pop(context);
              },
              child: Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}