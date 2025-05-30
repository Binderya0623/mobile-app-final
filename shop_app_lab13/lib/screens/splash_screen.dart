import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/global_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final globalProvider = context.read<GlobalProvider>();
    await globalProvider.initializeFirebase();
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        globalProvider.isLoggedIn ? '/' : '/login',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Consumer<GlobalProvider>(
              builder: (context, provider, child) {
                if (provider.error != null) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "Initialization Error: ${provider.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                return provider.isFirebaseInitialized
                  ? const Text("Loading user data...")
                  : const Text("Initializing Firebase...");
              },
            ),
          ],
        ),
      ),
    );
  }
}