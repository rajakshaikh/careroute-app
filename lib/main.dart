import 'screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ Package imported
import 'firebase_options.dart';
import 'screens/patient_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  // 1. Initialize Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load the Secret Keys from .env
  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env file loaded successfully");
  } catch (e) {
    print("❌ Error loading .env file: $e");
  }

  // 3. Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareRoute',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ✅ HomeScreen Section
class HomeScreen extends StatefulWidget {
  final String ashaName;
  final String regionId;

  const HomeScreen({super.key, required this.ashaName, required this.regionId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      PatientListScreen(regionId: widget.regionId),
      const MapScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome back,",
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            Text(
              widget.ashaName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                widget.ashaName.isNotEmpty ? widget.ashaName[0].toUpperCase() : "A",
                style: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Patients'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
        ],
      ),
    );
  }
}