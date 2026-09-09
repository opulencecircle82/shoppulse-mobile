import 'package:flutter/material.dart';
import '../models/job_ticket.dart';
import '../models/shop.dart';
import '../services/job_service.dart';
import '../services/shop_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'job_verification_screen.dart';
import 'login_screen.dart';

class JobListScreen extends StatefulWidget {
  final StaffContext staffContext;

  const JobListScreen({super.key, required this.staffContext});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  final _jobService = JobService();
  final _shopService = ShopService();
  final _authService = AuthService();

  Shop? _shop;
  List<JobTicket> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final shop = await _shopService.fetchShop(widget.staffContext.shopId);
    final tickets =
        await _jobService.fetchAssignedJobs(widget.staffContext.staffId);
    if (!mounted) return;
    setState(() {
      _shop = shop;
      _tickets = tickets;
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
          child: _tickets.isEmpty
              ? ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No jobs assigned to you yet.',
                        style: TextStyle(color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ticket = _tickets[index];
                    return _JobCard(
                      ticket: ticket,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => JobVerificationScreen(
                              ticket: ticket,
                              shop: shop,
                            ),
                          ),
                        );
                        _load();
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobTicket ticket;
  final VoidCallback onTap;

  const _JobCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          ticket.clientName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${ticket.serviceType}\n${ticket.serviceAddress}',
            style: const TextStyle(color: Colors.white54),
          ),
        ),
        isThreeLine: true,
        trailing: Chip(
          label: Text(
            ticket.status,
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
        ),
      ),
    );
  }
}
