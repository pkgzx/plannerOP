import 'package:flutter/material.dart';
import 'package:plannerop/store/assignments.dart';
import 'pages/login.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AssignmentsProvider()),
        // Otros providers que puedas tener
      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planeador de Operaciones',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
      routes: {
        '/login': (context) =>
            const LoginPage(), // Ruta para la página de login
      },
    );
  }
}
