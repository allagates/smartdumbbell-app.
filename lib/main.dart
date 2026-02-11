import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'providers/workout_provider.dart';
import 'providers/bluetooth_provider.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser la base de données
  await DatabaseService.instance.database;
  
  // Orientation portrait uniquement
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const SmartDumbbellApp());
}

class SmartDumbbellApp extends StatelessWidget {
  const SmartDumbbellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
      ],
      child: MaterialApp(
        title: 'SmartDumbbell',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF667eea),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Color(0xFF2D3748),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
