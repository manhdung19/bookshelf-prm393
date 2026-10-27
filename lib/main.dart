import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/book_list_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BookShelfApp());
}

/// Root widget of the application.
class BookShelfApp extends StatelessWidget {
  const BookShelfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookShelf',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

/// Alias for [BookShelfApp] to preserve compatibility with existing test references.
typedef MyApp = BookShelfApp;

/// Listens to [FirebaseAuth.authStateChanges] to direct users to either
/// the authenticated area ([BookListScreen]) or the unauthenticated [HomeScreen].
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading indicator while authentication state is unknown
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Authenticated users see the protected List area
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          return BookListScreen(
            userId: user.uid,
            email: user.email ?? '',
          );
        }

        // Unauthenticated users see Home
        return const HomeScreen();
      },
    );
  }
}
