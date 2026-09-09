import 'package:flutter/material.dart';
import '../models/job_ticket.dart';
import '../models/shop.dart';
import '../services/job_service.dart';
import '../services/shop_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'job_verification_screen.dart';
import 'login_screen.dart';

/// Home screen for a signed-in technician: just today's one job, not a
/// full job list. The owner assigns work one ticket at a time from the
/// dashboard's Kanban board, so the mobile app surfaces whichever ticket
/// is currently active (IN_PROGRESS) or, failing that, the next one
/// scheduled for them.
class HomeScreen extends StatefulWidget {
  final StaffContext staffContext;

  const HomeScreen({super.key, required this.staffContext});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _jobService = JobService();
  final _shopService = ShopService();
  final _authService = AuthService();

  Shop? _shop;
  JobTicket? _todayTask;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  JobTicket? _pickTodayTask(List<JobTicket> tickets) {
    for (final ticket in tickets) {
      if (ticket.status == 'IN_PROGRESS') return ticket;
    }
    for (final ticket in tickets.reversed) {
      if (ticket.status == 'SCHEDULED') return ticket;
    }
    return null;
  }

  Future<void> _load() async {
    final shop = await _shopService.fetchShop(widget.staffContext.shopId);
    final tickets =
        await _jobService.fetchAssignedJobs(widget.staffContext.staffId);
    if (!mounted) return;
    setState(() {
      _shop = shop;
      _todayTask = _pickTodayTask(tickets);
      _loading = false;
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _shop == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    final shop = _shop!;
    final task = _todayTask;

    return Theme(
      data: buildAppTheme(shop),
      child: Scaffold(
        appBar: AppBar(
          title: Text(shop.shopName),
          actions: [
            IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 8),
              const Text(
                "Today's Task",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              if (task == null)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'No job assigned to you right now.\nCheck back later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              else
                _TodayTaskCard(
                  ticket: task,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => JobVerificationScreen(
                          ticket: task,
                          shop: shop,
                        ),
                      ),
                    );
                    _load();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayTaskCard extends StatelessWidget {
  final JobTicket ticket;
  final VoidCallback onTap;

  const _TodayTaskCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isInProgress = ticket.status == 'IN_PROGRESS';

    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chip(
                label: Text(
                  isInProgress ? 'IN PROGRESS' : 'SCHEDULED',
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
                backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(height: 12),
              Text(
                ticket.clientName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ticket.serviceType,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Colors.white38, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ticket.serviceAddress,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  child: Text(
                    isInProgress ? 'Complete Job' : 'Start Job',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
