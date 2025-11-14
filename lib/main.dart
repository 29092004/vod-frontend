import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:movie_app/screens/auth/login.dart';
import 'package:movie_app/screens/home/Home_Screen.dart';
import 'package:movie_app/services/auth_service.dart';
import 'config/api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final isSignedIn = await GoogleSignIn().isSignedIn();
    if (isSignedIn) await GoogleSignIn().signOut();
  } catch (_) {}

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await dotenv.load(fileName: ".env");
  await Api.init();
  
  final isLoggedIn = await AuthService.tryAutoLogin();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VTCMovie',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: isLoggedIn ? const HomeScreen(email: '',) : const LoginScreen(),
    );
  }
}
