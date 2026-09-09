import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_ticket.dart';

class JobService {
  final _client = Supabase.instance.client;

  Future<List<JobTicket>> fetchAssignedJobs(String staffId) async {
    final rows = await _client
        .from('job_tickets')
        .select()
        .eq('assigned_staff_id', staffId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => JobTicket.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitStartProof({
    required String ticketId,
    required String photoUrl,
  }) async {
    await _client.from('job_tickets').update({
      'status': 'IN_PROGRESS',
      'start_photo_url': photoUrl,
      'started_at': DateTime.now().toIso8601String(),
    }).eq('id', ticketId);
  }

  Future<void> submitCompletionProof({
    required String ticketId,
    required String photoUrl,
  }) async {
    await _client.from('job_tickets').update({
      'status': 'COMPLETED',
      'end_photo_url': photoUrl,
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', ticketId);
  }
}
