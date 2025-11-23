import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Core imports
import 'core/themes/app_theme.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/patient_profile_view_model.dart';
import 'view_models/doctor_profile_view_model.dart';
import 'view_models/patient_home_view_model.dart';
import 'view_models/doctor_appointments_view_model.dart';
import 'view_models/availability_view_model.dart';
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
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),

        // This makes ProfileViewModel available to the entire app
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => DoctorProfileViewModel()),
        ChangeNotifierProvider(create: (_) => PatientHomeViewModel()),
        ChangeNotifierProvider(create: (_) => DoctorAppointmentsViewModel()),
        ChangeNotifierProvider(create: (_) => AvailabilityViewModel()),
      ],
      child: MaterialApp(
        title: 'ZenThink Health',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const LoginView(),
      ),
    );
  }
}
