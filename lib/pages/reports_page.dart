import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../services/storage_service.dart';

class ReportsPage extends StatefulWidget {
  final StorageService storage;
  const ReportsPage({super.key, required this.storage});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _range = 'Weekly';

  DateTimeRange _currentRange() {
    final now = DateTime.now();
    if (_range == 'Daily') {
      return DateTimeRange(start: DateTime(now.year, now.month, now.day), end: DateTime(now.year, now.month, now.day));
    } else if (_range == 'Monthly') {
      return DateTimeRange(start: DateTime(now.year, now.month, 1), end: DateTime(now.year, now.month + 1, 0));
    } else {
      final start = now.subtract(Duration(days: now.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return DateTimeRange(start: DateTime(start.year, start.month, start.day), end: DateTime(end.year, end.month, end.day));
    }
  }

  Future<void> _exportCsv() async {
    final range = _currentRange();
    final file = await widget.storage.exportExpensesCsv(range.start, range.end);
    await Share.shareXFiles([XFile(file.path)], text: 'Huella export');
  }

  @override
  Widget build(BuildContext context) {
    final range = _currentRange();
    final df = DateFormat('MMM d');
    final expensesByCat = widget.storage.expenseSumByCategory(range.start, range.end);
    final pieSections = expensesByCat.entries.map((e) => PieChartSectionData(value: e.value, title: e.key, color: Colors.primaries[e.key.hashCode % Colors.primaries.length])).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics'), actions: [
        IconButton(onPressed: _exportCsv, icon: const Icon(Icons.ios_share)),
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Date Range: '),
            DropdownButton<String>(
              value: _range,
              items: const [DropdownMenuItem(value: 'Daily', child: Text('Daily')), DropdownMenuItem(value: 'Weekly', child: Text('Weekly')), DropdownMenuItem(value: 'Monthly', child: Text('Monthly'))],
              onChanged: (v) => setState(() => _range = v ?? 'Weekly'),
            ),
            const Spacer(),
            Text('${df.format(range.start)} - ${df.format(range.end)}')
          ]),
          const SizedBox(height: 16),
          Text('Expenses by Category', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: PieChart(PieChartData(sections: pieSections.isEmpty ? [PieChartSectionData(value: 1, title: 'No data', color: Colors.grey.shade300)] : pieSections)),
          ),
          const SizedBox(height: 24),
          Text('Distance Over Time (placeholder)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: Colors.indigo,
                  barWidth: 3,
                  spots: List.generate(7, (i) => FlSpot(i.toDouble(), (i * 2 % 7).toDouble() + 1)),
                ),
              ],
            )),
          ),
        ]),
      ),
    );
  }
}


