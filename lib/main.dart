import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stridelog/controllers/activity_provider.dart';
import 'package:stridelog/controllers/auth_provider.dart';
import 'package:stridelog/theme.dart';
import 'package:stridelog/views/splash_screen.dart';
import 'package:stridelog/views/auth_screen.dart';
import 'package:stridelog/views/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ActivityProvider>(
          create: (context) => ActivityProvider(null),
          update: (context, auth, previousActivityProvider) =>
              ActivityProvider(auth),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Tracker - Monitor de Atividades Físicas',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/auth': (_) => const AuthScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}