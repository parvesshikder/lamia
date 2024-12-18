import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preownedhub/core/home/home.dart';
import 'package:preownedhub/core/login/enter_login_details_page.dart';
import 'package:preownedhub/core/register/enter_register_details_page.dart';
import 'package:preownedhub/core/register/register.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PREOWNEDHUB',
      theme: ThemeData(
        useMaterial3: true,
        
      ),
      debugShowCheckedModeBanner: false,
      // It start the app with the "/" named route. In this case, the app starts
      // on the HomeScreen widget.
      initialRoute: '/',
      routes: {
        // When navigating to the "/" route, build the login screen.
        '/': (context) => const HomePage(),
        '/login-details': (context) => const EnterLoginDetails(),
        '/register': (context) => const RegisterScreen(),
        '/register-details': (context) => const EnterRegisterDetails(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}


