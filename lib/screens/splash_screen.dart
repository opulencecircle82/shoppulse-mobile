import 'package:flutter/material.dart';
import '../config/supabase_config.dart';
import '../services/auth_service.dart';
import '../services/shop_service.dart';
import 'login_screen.dart';
import 'job_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService();
  final _shopService = ShopService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveSession());
  }

  Future<void> _resolveSession() async {
    if (!SupabaseConfig.isConfigured) return;

    final user = _authService.currentUser;
    if (!mounted) return;

    if (user == null) {
      _goTo(const LoginScreen());
      return;
    }

    final staff = await _shopService.fetchCurrentStaff();
    if (!mounted) return;

    if (staff == null) {
      _goTo(const LoginScreen());
      return;
    }

    _goTo(JobListScreen(staffContext: staff));
  }

  void _goTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Missing SUPABASE_URL / SUPABASE_ANON_KEY.\n'
              'Run with --dart-define to configure.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );
  }
}
