import 'package:flutter/material.dart';
import 'package:local_tasks/widget/app/app_shell.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocalTasks',
      theme: ThemeData(useMaterial3: true),
      home: const AppShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
