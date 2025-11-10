import 'package:flutter/material.dart';
import 'package:project_mobileprog/api/api_service.dart';
import 'package:project_mobileprog/screens/welcome_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STMIK Widya Utama',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),

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
            return const WelcomeScreen();
          } else {
            return const LoginScreen(); // nanti bisa diganti Dashboard
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

