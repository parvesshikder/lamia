import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preownedhub/pages/home/home.dart';
import 'package:preownedhub/pages/login/enter_login_details_page.dart';
import 'package:preownedhub/pages/login/login.dart';
import 'package:preownedhub/pages/register/enter_register_details_page.dart';
import 'package:preownedhub/pages/register/register.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PREOWNEDHUB',
      theme: ThemeData(
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: FirebaseAuth.instance.currentUser != null ? '/home' : '/',
      routes: {
        '/': (context) => const LoginScrren(),
        '/login-details': (context) => const EnterLoginDetails(),
        '/register': (context) => const RegisterScreen(),
        '/register-details': (context) => const EnterRegisterDetails(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
