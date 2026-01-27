import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_crashlytics/crashlytics_logger.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Pass all uncaught errors ke Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors ke Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Crashlytics Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _initializeCrashlytics();
  }

  Future<void> _initializeCrashlytics() async {
    // Set user ID (contoh: dari login)
    await CrashlyticsLogger.setUserId('user_demo_123');

    // Set custom keys yang persistent
    await CrashlyticsLogger.setCustomKey('app_version', '1.0.0');
    await CrashlyticsLogger.setCustomKey('environment', 'production');

    // Log app start
    await CrashlyticsLogger.logEvent(
      eventId: 'app_start',
      eventName: 'App Started',
      description: 'User membuka aplikasi',
    );
  }

  Future<void> _incrementCounter() async {
    // Log event sebelum action
    await CrashlyticsLogger.logEvent(
      eventId: 'add_counter',
      eventName: 'Add Counter Button',
      description: 'User menekan tombol tambah counter',
      additionalData: {
        'counter_value_before': _counter,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    setState(() {
      _counter++;
    });

    // Log setelah action berhasil
    await CrashlyticsLogger.logEvent(
      eventId: 'add_counter_success',
      eventName: 'Add Counter Success',
      description: 'Counter berhasil ditambah',
      additionalData: {'counter_value_after': _counter},
    );
  }

  Future<void> _decrementCounter() async {
    await CrashlyticsLogger.logEvent(
      eventId: 'subtract_counter',
      eventName: 'Subtract Counter Button',
      description: 'User menekan tombol kurang counter',
      additionalData: {'counter_value_before': _counter},
    );

    setState(() {
      _counter--;
    });
  }

  Future<void> _resetCounter() async {
    await CrashlyticsLogger.logEvent(
      eventId: 'reset_counter',
      eventName: 'Reset Counter Button',
      description: 'User mereset counter ke 0',
      additionalData: {'counter_value_before': _counter},
    );

    setState(() {
      _counter = 0;
    });
  }

  Future<void> _simulateError() async {
    try {
      await CrashlyticsLogger.logEvent(
        eventId: 'simulate_error',
        eventName: 'Simulate Error Button',
        description: 'User mencoba simulasi error',
      );

      // Simulate error
      throw Exception('Ini adalah contoh error untuk testing Crashlytics');
    } catch (e, stackTrace) {
      // CARA BARU: Gunakan logNonFatalError untuk guarantee visibility
      await CrashlyticsLogger.logNonFatalError(
        eventId: 'simulate_error',
        eventName: 'Simulate Error Button',
        error: e,
        stackTrace: stackTrace,
        additionalData: {
          'counter_value': _counter,
          'action': 'simulate_error_clicked',
          'screen': 'home',
        },
      );

      // Show error ke user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Non-fatal error logged: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _simulateDivisionByZero() async {
    try {
      await CrashlyticsLogger.logEvent(
        eventId: 'division_operation',
        eventName: 'Division Operation',
        description: 'User melakukan operasi pembagian',
        additionalData: {'divisor': 0},
      );

      // Ini akan menyebabkan error
      int result = 100 ~/ 0;
      if (kDebugMode) {
        print(result);
      }
    } catch (e, stackTrace) {
      // Gunakan logNonFatalError untuk non-fatal errors
      await CrashlyticsLogger.logNonFatalError(
        eventId: 'division_operation',
        eventName: 'Division Operation',
        error: e,
        stackTrace: stackTrace,
        additionalData: {
          'operation_type': 'division_by_zero',
          'dividend': 100,
          'divisor': 0,
          'counter_at_error': _counter,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Non-fatal error: Division by zero logged!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Firebase Crashlytics Demo'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Counter Value:', style: TextStyle(fontSize: 20)),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 30),

              // Counter buttons
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: _incrementCounter,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Counter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _decrementCounter,
                    icon: const Icon(Icons.remove),
                    label: const Text('Subtract Counter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _resetCounter,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Counter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),

              const Text(
                'Error Testing:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Error testing buttons
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: _simulateError,
                    icon: const Icon(Icons.error_outline),
                    label: const Text('Simulate Error'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _simulateDivisionByZero,
                    icon: const Icon(Icons.warning),
                    label: const Text('Division by Zero'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      CrashlyticsLogger.forceCrash();
                    },
                    icon: const Icon(Icons.dangerous),
                    label: const Text('Force Crash'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[900],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ℹ️ Info:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Setiap button memiliki event_id dan event_name yang unik\n'
                        '• Error akan ter-log dengan context yang jelas\n'
                        '• Check Firebase Console untuk melihat logs\n'
                        '• Force Crash untuk testing saja!',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
