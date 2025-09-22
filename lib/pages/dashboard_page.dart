import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';

class DashboardPage extends StatelessWidget {
  final StorageService storage;
  const DashboardPage({super.key, required this.storage});

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final dateStr = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hello, ${user?.displayName ?? user?.email ?? 'User'}'),
          Text(dateStr, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
        ]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryCard(title: 'Time Today', value: _formatDuration(storage.timeLoggedToday), icon: Icons.timer),
                _SummaryCard(title: 'Distance Today', value: '${(storage.distanceTodayMeters / 1000).toStringAsFixed(2)} km', icon: Icons.directions_walk),
                _SummaryCard(title: 'Expenses Today', value: '₹ ${storage.expensesForDate(DateTime.now()).fold<double>(0, (p, e) => p + e.amount).toStringAsFixed(2)}', icon: Icons.attach_money),
              ],
            ),
            const SizedBox(height: 20),
            Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionButton(
                  icon: Icons.play_circle_fill,
                  label: 'Start New Task',
                  onTap: () => Navigator.of(context).pushNamed('/tracking'),
                ),
                _ActionButton(
                  icon: Icons.receipt_long,
                  label: 'Log Expense',
                  onTap: () => Navigator.of(context).pushNamed('/expense'),
                ),
                _ActionButton(
                  icon: Icons.analytics_outlined,
                  label: 'View Reports',
                  onTap: () => Navigator.of(context).pushNamed('/reports'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _SummaryCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
}


