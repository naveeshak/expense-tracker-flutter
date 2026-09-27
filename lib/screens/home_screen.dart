import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../pages.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ExpenseService _expenseService = ExpenseService();

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  String _selectedCategory = 'All';
  DateTime _selectedMonth = DateTime.now();

  final List<String> _categories = [
    'All',
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Health',
    'Education',
    'Entertainment',
    'Other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExpenseModel> _applyFilters(List<ExpenseModel> expenses) {
    return expenses.where((expense) {
      final matchesCategory =
          _selectedCategory == 'All' ||
          expense.category == _selectedCategory;

      final matchesMonth =
          expense.date.year == _selectedMonth.year &&
          expense.date.month == _selectedMonth.month;

      final query = _searchQuery.toLowerCase().trim();

      final matchesSearch =
          query.isEmpty ||
          expense.title.toLowerCase().contains(query) ||
          expense.category.toLowerCase().contains(query) ||
          expense.note.toLowerCase().contains(query);

      return matchesCategory && matchesMonth && matchesSearch;
    }).toList();
  }

  double _getTotal(List<ExpenseModel> expenses) {
    return expenses.fold(
      0,
      (sum, expense) => sum + expense.amount,
    );
  }

  Future<void> _changeMonth() async {
    int selectedYear = _selectedMonth.year;
    int selectedMonth = _selectedMonth.month;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Month'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      12,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text(
                          _monthName(index + 1),
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedMonth = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      10,
                      (index) {
                        final year = DateTime.now().year - 5 + index;

                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      },
                    ),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedYear = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      DateTime(
                        selectedYear,
                        selectedMonth,
                      ),
                    );
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedMonth = result;
      });
    }
  }

  Map<String, double> _getCategoryTotals(List<ExpenseModel> expenses) {
    final Map<String, double> totals = {};

    for (final expense in expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }

    return totals;
  }

  List<PieChartSectionData> _buildPieSections(
    Map<String, double> categoryTotals,
  ) {
    final total = categoryTotals.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    final colors = [
      Colors.indigo,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.blue,
      Colors.amber,
    ];

    int index = 0;

    return categoryTotals.entries.map((entry) {
      final percentage =
          total == 0 ? 0.0 : (entry.value / total) * 100;

      final section = PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        color: colors[index % colors.length],
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );

      index++;

      return section;
    }).toList();
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: Text(
            'Are you sure you want to delete "${expense.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _expenseService.deleteExpense(expense.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense deleted successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete expense: $e'),
        ),
      );
    }
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Transport':
        return Icons.directions_car_outlined;
      case 'Shopping':
        return Icons.shopping_bag_outlined;
      case 'Bills':
        return Icons.receipt_long_outlined;
      case 'Health':
        return Icons.health_and_safety_outlined;
      case 'Education':
        return Icons.school_outlined;
      case 'Entertainment':
        return Icons.movie_outlined;
      default:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Expense Tracker',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: widget.isDarkMode ? 'Light mode' : 'Dark mode',
            onPressed: widget.onToggleTheme,
            icon: Icon(
              widget.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ExpenseFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<ExpenseModel>>(
          stream: _expenseService.getExpenses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Unable to load expenses',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final expenses = snapshot.data ?? [];
            final filteredExpenses = _applyFilters(expenses);
            final total = _getTotal(filteredExpenses);
            final categoryTotals = _getCategoryTotals(filteredExpenses);

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  110,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Expenses',
                          style: TextStyle(
                            fontSize: 15,
                            color: colorScheme.onPrimaryContainer
                                .withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Rs. ${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_monthName(_selectedMonth.month)} '
                          '${_selectedMonth.year}',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search expenses...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();

                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
                          items: _categories
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    category,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _changeMonth,
                            icon: const Icon(
                              Icons.calendar_month_outlined,
                              size: 20,
                            ),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${_monthName(_selectedMonth.month)} '
                                '${_selectedMonth.year}',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_selectedCategory == 'All' && categoryTotals.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Category Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 95,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: categoryTotals.entries.map((entry) {
                          return Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  entry.key,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Rs. ${entry.value.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  if (_selectedCategory == 'All' && categoryTotals.isNotEmpty) ...[
                    const SizedBox(height: 28),

                    Text(
                      'Expense Chart',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieSections(categoryTotals),
                          centerSpaceRadius: 45,
                          sectionsSpace: 3,
                          borderData: FlBorderData(
                            show: false,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: categoryTotals.entries
                          .toList()
                          .asMap()
                          .entries
                          .map((item) {
                        final index = item.key;
                        final entry = item.value;

                        final colors = [
                          Colors.indigo,
                          Colors.orange,
                          Colors.green,
                          Colors.purple,
                          Colors.red,
                          Colors.teal,
                          Colors.blue,
                          Colors.amber,
                        ];

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 28),
                  Text(
                    'Expense History',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 14),
                  if (expenses.isEmpty)
                    const _EmptyState(
                      title: 'No expenses yet',
                      message:
                          'Tap "Add Expense" to create your first expense.',
                    )
                  else if (filteredExpenses.isEmpty)
                    const _EmptyState(
                      title: 'No matching expenses',
                      message:
                          'Try changing the month or category filter.',
                    )
                  else
                    ...filteredExpenses.map(
                      (expense) => _ExpenseCard(
                        expense: expense,
                        icon: _getCategoryIcon(expense.category),
                        formattedDate: _formatDate(expense.date),
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExpenseFormScreen(
                                expense: expense,
                              ),
                            ),
                          );
                        },
                        onDelete: () {
                          _deleteExpense(expense);
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final IconData icon;
  final String formattedDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.icon,
    required this.formattedDate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                icon,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(expense.category),
                  const SizedBox(height: 2),
                  Text(formattedDate),
                  if (expense.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      expense.note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs. ${expense.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyState({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 48,
        horizontal: 24,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}