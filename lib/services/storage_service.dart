import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final _client = Supabase.instance.client;

  Future<String> uploadJobPhoto({
    required String shopId,
    required String ticketId,
    required File file,
  }) async {
    final ext = file.path.split('.').last;
    final path =
        '$shopId/$ticketId-${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('job-photos').upload(path, file);

    return _client.storage.from('job-photos').getPublicUrl(path);
  }
}
