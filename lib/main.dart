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
import 'view_models/patient_appointments_view_model.dart';
import 'view_models/patient_medical_records_view_model.dart';
import 'view_models/availability_view_model.dart';
import 'view_models/admin_doctors_view_model.dart';
import 'view_models/admin_appointments_view_model.dart';
import 'views/screens/admin/admin_dashboard_screen.dart';
import 'views/screens/admin/verify_doctors_screen.dart';
import 'views/screens/auth/login_view.dart';
import 'views/screens/patient_navigation.dart';
import 'views/screens/doctor_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        ChangeNotifierProvider(create: (_) => PatientAppointmentsViewModel()),
        ChangeNotifierProvider(create: (_) => PatientMedicalRecordsViewModel()),
        ChangeNotifierProvider(create: (_) => AvailabilityViewModel()),
        ChangeNotifierProvider(create: (_) => AdminDoctorsViewModel()),
        ChangeNotifierProvider(create: (_) => AdminAppointmentsViewModel()),
      ],
        child: MaterialApp(
          title: 'ZenThink Health',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const AuthGate(),
          routes: {
            '/admin': (ctx) => const AdminDashboardScreen(),
            '/admin/verify-doctors': (ctx) => const VerifyDoctorsScreen(),
          },
        ),
    );
  }
}

// Simple auth gate to decide initial screen based on Firebase cached auth
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    await authVM.loadCurrentUser();
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final authVM = Provider.of<AuthViewModel>(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginView();

    if (authVM.userRole == 'doctor') return const DoctorNavigation();
    if (authVM.userRole == 'admin') return const AdminDashboardScreen();

    return const PatientNavigation();
  }
}
