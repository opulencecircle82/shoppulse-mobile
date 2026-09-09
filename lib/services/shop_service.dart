import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shop.dart';

class StaffContext {
  final String staffId;
  final String shopId;
  final String role;

  const StaffContext({
    required this.staffId,
    required this.shopId,
    required this.role,
  });
}

class ShopService {
  final _client = Supabase.instance.client;

  /// Looks up the staff_members row linked to the signed-in auth user, so we
  /// know which shop's job board and theme to load.
  Future<StaffContext?> fetchCurrentStaff() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await _client
        .from('staff_members')
        .select('id, shop_id, role')
        .eq('auth_user_id', userId)
        .maybeSingle();

    if (row == null) return null;

    return StaffContext(
      staffId: row['id'] as String,
      shopId: row['shop_id'] as String,
      role: row['role'] as String,
    );
  }

  Future<Shop?> fetchShop(String shopId) async {
    final row = await _client
        .from('shops')
        .select()
        .eq('id', shopId)
        .maybeSingle();

    if (row == null) return null;
    return Shop.fromJson(row);
  }
}
