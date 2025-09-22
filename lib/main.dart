import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:huella/pages/home_page.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'signup.dart';
import 'pages/tracking_page.dart';
import 'pages/expense_page.dart';
import 'pages/reports_page.dart';
import 'pages/home_page.dart' as trips_home;
import 'services/tracking_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();
    final tracking = TrackingService();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Huella App',
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/signup': (context) => const SignUpPage(),
        '/tracking': (context) =>
            TrackingPage(trackingService: tracking, storageService: storage),
        '/expense': (context) => ExpensePage(storage: storage),
        '/reports': (context) => ReportsPage(storage: storage),
      },
    );
  }
}