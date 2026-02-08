import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_crashlytics/app_logger.dart';
import 'package:flutter_crashlytics/crashlytics_logger.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Flutter framework error
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Async / isolate error
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
    _initializeAppLogging();
  }

  Future<void> _initializeAppLogging() async {
    await CrashlyticsLogger.setUserId('user_demo_123');

    await CrashlyticsLogger.setCustomKey('app_version', '1.0.0');
    await CrashlyticsLogger.setCustomKey('environment', 'production');

    await CrashlyticsLogger.logEvent(
      eventId: 'app_start',
      eventName: 'App Started',
      description: 'User membuka aplikasi',
    );
  }

  Future<void> _incrementCounter() async {
    await AppLogger.logAction(
      analyticsEvent: 'add_counter',
      analyticsParams: {'counter_before': _counter},
      crashEventId: 'add_counter',
      crashEventName: 'Add Counter Button',
    );

    setState(() {
      _counter++;
    });

    await AppLogger.logAction(
      analyticsEvent: 'add_counter_success',
      analyticsParams: {'counter_after': _counter},
      crashEventId: 'add_counter_success',
      crashEventName: 'Add Counter Success',
    );
  }

  Future<void> _decrementCounter() async {
    await AppLogger.logAction(
      analyticsEvent: 'subtract_counter',
      analyticsParams: {'counter_before': _counter},
      crashEventId: 'subtract_counter',
      crashEventName: 'Subtract Counter Button',
    );

    setState(() {
      _counter--;
    });
  }

  Future<void> _resetCounter() async {
    await AppLogger.logAction(
      analyticsEvent: 'reset_counter',
      analyticsParams: {'counter_before': _counter},
      crashEventId: 'reset_counter',
      crashEventName: 'Reset Counter Button',
    );

    setState(() {
      _counter = 0;
    });
  }

  Future<void> _simulateError() async {
    try {
      await AppLogger.logAction(
        analyticsEvent: 'simulate_error_click',
        crashEventId: 'simulate_error_click',
        crashEventName: 'Simulate Error Button',
      );

      throw Exception('Ini adalah contoh error untuk testing Crashlytics');
    } catch (e, stackTrace) {
      await CrashlyticsLogger.logNonFatalError(
        eventId: 'simulate_error',
        eventName: 'Simulate Error',
        error: e,
        stackTrace: stackTrace,
        additionalData: {'counter_value': _counter, 'screen': 'home'},
      );

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
      await AppLogger.logAction(
        analyticsEvent: 'division_operation',
        analyticsParams: {'divisor': 0},
        crashEventId: 'division_operation',
        crashEventName: 'Division Operation',
      );

      int result = 100 ~/ 0;
      debugPrint(result.toString());
    } catch (e, stackTrace) {
      await CrashlyticsLogger.logNonFatalError(
        eventId: 'division_by_zero',
        eventName: 'Division by Zero',
        error: e,
        stackTrace: stackTrace,
        additionalData: {'dividend': 100, 'divisor': 0, 'counter': _counter},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Division by zero logged'),
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
