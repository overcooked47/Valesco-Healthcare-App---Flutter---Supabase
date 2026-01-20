import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'services/medication_reminder_service.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/health_profile_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/health_reading_provider.dart';
import 'providers/hospital_provider.dart';
import 'providers/emergency_provider.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/verification_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/health_profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/emergency_contacts_screen.dart';
import 'screens/profile/medical_documents_screen.dart';
import 'screens/medication/medication_screen.dart';
import 'screens/medication/add_medication_screen.dart';
import 'screens/medication/medication_calendar_screen.dart';
import 'screens/hospital/hospital_screen.dart';
import 'screens/hospital/ambulance_screen.dart';
import 'screens/emergency/emergency_screen.dart';
import 'screens/health/health_readings_screen.dart';
import 'screens/health/add_reading_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nfhlhuqkfqpozfmadlpd.supabase.co',
    anonKey: 'sb_publishable_Jt_SXU43xuH2hrpEVoLEOw_Bm33esb_',
  );
  // Initialize timezone database
  tz.initializeTimeZones();

  // Initialize medication reminder service
  await MedicationReminderService.instance.initialize();

  runApp(const ValESCOApp());
}

// Global Supabase client accessor
final supabase = Supabase.instance.client;

class ValESCOApp extends StatelessWidget {
  const ValESCOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HealthProfileProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => HealthReadingProvider()),
        ChangeNotifierProvider(create: (_) => HospitalProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/verify': (context) => const VerificationScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const HealthProfileScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/emergency-contacts': (context) => const EmergencyContactsScreen(),
          '/medical-documents': (context) => const MedicalDocumentsScreen(),
          '/medications': (context) => const MedicationScreen(),
          '/add-medication': (context) => const AddMedicationScreen(),
          '/medication-calendar': (context) => const MedicationCalendarScreen(),
          '/hospitals': (context) => const HospitalScreen(),
          '/ambulance': (context) => const AmbulanceScreen(),
          '/emergency': (context) => const EmergencyScreen(),
          '/health-readings': (context) => const HealthReadingsScreen(),
          '/add-reading': (context) => const AddReadingScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _dataInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SplashLogo(),
                  SizedBox(height: 24),
                  CircularProgressIndicator(color: AppColors.primaryOrange),
                ],
              ),
            ),
          );
        }

        if (authProvider.isLoggedIn) {
          // Initialize data when logged in (only once)
          if (!_dataInitialized) {
            _dataInitialized = true;
            _initializeData(context);
          }
          return const HomeScreen();
        }

        // Reset flag when logged out
        _dataInitialized = false;
        return const LoginScreen();
      },
    );
  }

  void _initializeData(BuildContext context) {
    // Load initial data after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<HealthProfileProvider>().loadProfile();
        await context.read<MedicationProvider>().loadMedications();
        await context.read<HealthReadingProvider>().loadReadings();
      } catch (e) {
        debugPrint('Error initializing data: $e');
      }
    });
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: 50,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.appName,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = AppColors.primaryGradient.createShader(
                const Rect.fromLTWH(0, 0, 200, 50),
              ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your Health Companion',
          style: TextStyle(fontSize: 14, color: AppColors.grey500),
        ),
      ],
    );
  }
}
