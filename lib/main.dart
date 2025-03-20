import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/store/auth.dart';
import 'package:plannerop/store/clients.dart';
import 'package:plannerop/store/faults.dart';
import 'package:plannerop/store/task.dart';
import 'package:plannerop/store/user.dart';
import 'pages/login.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/workers.dart';
import 'package:flutter_animated_splash/flutter_animated_splash.dart';

Future<void> main() async {
  // Asegúrate de inicializar Flutter
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AssignmentsProvider()),
        ChangeNotifierProvider(create: (context) => WorkersProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => AreasProvider()),
        ChangeNotifierProvider(create: (context) => TasksProvider()),
        ChangeNotifierProvider(create: (context) => ClientsProvider()),
        ChangeNotifierProvider(create: (context) => FaultsProvider()),
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Eliminar el MaterialApp anidado
      home: AnimatedSplash(
        type: Transition.size,
        curve: Curves.easeInOut,
        backgroundColor: Colors.blue,
        navigator: const LoginPage(),
        durationInSeconds: 2,
        child: Image.asset(
          "assets/splash.png",
          width: 200,
          height: 200,
        ),
      ),
      routes: {
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
