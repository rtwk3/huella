import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../models/trip_models.dart';

class ExpenseEntry {
  final double amount;
  final String category;
  final String description;
  final DateTime date;

  ExpenseEntry({required this.amount, required this.category, required this.description, required this.date});
}

class StorageService {
  final List<ExpenseEntry> _expenses = <ExpenseEntry>[];
  final List<Trip> _trips = <Trip>[];
  final List<Traveller> _travellers = <Traveller>[];
  Duration timeLoggedToday = Duration.zero;
  double distanceTodayMeters = 0;

  void addTimeAndDistance(Duration elapsed, double distanceMeters) {
    timeLoggedToday += elapsed;
    distanceTodayMeters += distanceMeters;
  }

  void addExpense(ExpenseEntry entry) {
    _expenses.add(entry);
  }

  List<ExpenseEntry> expensesForDate(DateTime date) {
    final df = DateFormat('yyyy-MM-dd');
    return _expenses.where((e) => df.format(e.date) == df.format(date)).toList();
  }

  Map<String, double> expenseSumByCategory(DateTime from, DateTime to) {
    final Map<String, double> sums = {};
    for (final e in _expenses) {
      if (e.date.isAfter(from.subtract(const Duration(days: 1))) && e.date.isBefore(to.add(const Duration(days: 1)))) {
        sums[e.category] = (sums[e.category] ?? 0) + e.amount;
      }
    }
    return sums;
  }

  Future<File> exportExpensesCsv(DateTime from, DateTime to) async {
    final rows = <List<dynamic>>[
      ['date', 'category', 'amount', 'description']
    ];
    final df = DateFormat('yyyy-MM-dd');
    for (final e in _expenses) {
      if (e.date.isAfter(from.subtract(const Duration(days: 1))) && e.date.isBefore(to.add(const Duration(days: 1)))) {
        rows.add([df.format(e.date), e.category, e.amount.toStringAsFixed(2), e.description]);
      }
    }
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.csv');
    return file.writeAsString(csv);
  }

  // Trips
  List<Trip> listTrips({String query = ''}) {
    if (query.isEmpty) return List<Trip>.from(_trips);
    final q = query.toLowerCase();
    return _trips.where((t) =>
      t.title.toLowerCase().contains(q) ||
      t.subtitle.toLowerCase().contains(q) ||
      t.origin.toLowerCase().contains(q) ||
      t.destination.toLowerCase().contains(q)
    ).toList();
  }

  void addTrip(Trip trip) {
    _trips.add(trip);
  }

  // Travellers
  List<Traveller> listTravellers() => List<Traveller>.from(_travellers);
  void addTraveller(Traveller traveller) => _travellers.add(traveller);
}


