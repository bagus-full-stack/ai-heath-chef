import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// On importe notre routeur personnalisé
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Supabase (les clés seront à changer plus tard)
  await Supabase.initialize(
    url: 'https://atmandnlqyyjaofezyig.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0bWFuZG5scXl5amFvZmV6eWlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2Nzc4OTUsImV4cCI6MjA4NjI1Mzg5NX0.MHmN5m1rqJvSnMHda9kYplXXnA7KsJBJBgnyptrpq1A',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI Health Chef',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B66FF),
          background: Colors.white,
        ),
        useMaterial3: true,
      ),
      // On connecte simplement la variable de notre nouveau fichier
      routerConfig: appRouter,
    );
  }
}