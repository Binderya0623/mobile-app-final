import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app_lab13/provider/global_provider.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/splash_screen.dart';
import 'services/httpService.dart';
import 'repository/repository.dart';
import 'provider/language_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GlobalProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        Provider(create: (context) => HttpService(baseUrl: 'https://fakestoreapi.com')),
        ProxyProvider<HttpService, MyRepository>(
          update: (context, httpService, previous) => MyRepository(httpService: httpService)
        ),
      ], 
      child: const MyApp()
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shop app',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => HomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage()
      },
    );
  }
}