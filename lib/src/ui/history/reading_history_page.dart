import 'package:flutter/material.dart';
import '../../domain/models/reading_history.dart';
import '../../domain/repository/reading_history_repository.dart';
import '../../mushaf_library.dart';
import 'reading_history_view_model.dart';

/// Premium Reading History Page (Issue #45).
class ReadingHistoryPage extends StatefulWidget {
  final Function(int)? onPageSelected;
  const ReadingHistoryPage({super.key, this.onPageSelected});

  @override
  State<ReadingHistoryPage> createState() => _ReadingHistoryPageState();
}

class _ReadingHistoryPageState extends State<ReadingHistoryPage> {
  late ReadingHistoryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ReadingHistoryViewModel(
      readingHistoryRepository: MushafLibrary.getReadingHistoryRepository(),
    );
    _viewModel.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showClearDialog(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.stats == null && _viewModel.recentHistory.isEmpty) {
            return _buildEmptyState();
          }

          return CustomScrollView(
            slivers: [
              // Stats Summary
              if (_viewModel.stats != null)
                SliverToBoxAdapter(
                  child: _buildStatsGrid(_viewModel.stats!),
                ),

              // Recent History Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text(
                    'Recent Sessions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // History List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final history = _viewModel.recentHistory[index];
                      return _HistoryTile(
                        history: history,
                        onTap: () => widget.onPageSelected?.call(history.pageNumber),
                      );
                    },
                    childCount: _viewModel.recentHistory.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(ReadingStats stats) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Pages Read',
                  value: '${stats.totalPagesRead}',
                  icon: Icons.auto_stories,
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _StatCard(
                  title: 'Streak',
                  value: '${stats.currentStreak} Days',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Time',
                  value: '${stats.totalReadingTimeHours}h ${stats.totalReadingTimeMinutes % 60}m',
                  icon: Icons.timer,
                  color: Colors.teal,
                ),
              ),
              Expanded(
                child: _StatCard(
                  title: 'Daily Avg',
                  value: '${stats.averageDailyMinutes}m',
                  icon: Icons.query_stats,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'No reading history yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start reading to see your analytics here!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all reading history and stats?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _viewModel.clearHistory();
              Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(title, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ReadingHistory history;
  final VoidCallback onTap;

  const _HistoryTile({required this.history, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(history.timestamp);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: const Icon(Icons.menu_book, size: 20),
        ),
        title: Text(
          'Page ${history.pageNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${date.day}/${date.month}/${date.year} · ${history.durationMinutes} minutes'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
