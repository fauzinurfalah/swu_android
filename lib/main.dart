import 'package:flutter/material.dart';
import 'package:project_mobileprog/api/api_service.dart';
import 'package:project_mobileprog/screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initialize locale data for Intl (used by DateFormat)
  // use 'id_ID' to match DateFormat locale identifiers
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STMIK Widya Utama',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),

      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(color: Colors.white, child: child),
          ),
        );
      },

      home: FutureBuilder(
        future: ApiService.getSession(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const HomeScreen();
          } else {
            return const HomeScreen(); // nanti bisa diganti Dashboard
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
