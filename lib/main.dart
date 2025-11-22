import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Core imports
import 'core/themes/app_theme.dart';
import 'view_models/auth_view_model.dart';
// Update this import to point to the new location
import 'views/screens/auth/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ZenThinkApp());
}

class ZenThinkApp extends StatelessWidget {
  const ZenThinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthViewModel())],
      child: MaterialApp(
        title: 'ZenThink Health',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Point to the separated LoginView
        home: const LoginView(),
      ),
    );
  }
}
