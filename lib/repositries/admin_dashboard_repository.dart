import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/admin_dashboard_model.dart';

class AdminDashboardRepository {
  AdminDashboardRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<AdminDashboardSnapshot> fetchSnapshot() async {
    final response = await _client.rpc('admin_get_dashboard_snapshot');
    final row = _singleMap(response);
    return AdminDashboardSnapshot.fromJson(row);
  }

  Future<List<AdminUserRecord>> fetchUsers({
    String search = '',
    String role = 'all',
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client.rpc(
      'admin_list_users',
      params: {
        'p_search': search.trim().isEmpty ? null : search.trim(),
        'p_role': role == 'all' ? null : role,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return _rows(response).map(AdminUserRecord.fromJson).toList();
  }

  Future<List<AdminWorkItemRecord>> fetchWorkItems({
    String search = '',
    String status = 'all',
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _client.rpc(
      'admin_list_work_items',
      params: {
        'p_search': search.trim().isEmpty ? null : search.trim(),
        'p_status': status == 'all' ? null : status,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return _rows(response).map(AdminWorkItemRecord.fromJson).toList();
  }

  Map<String, dynamic> _singleMap(dynamic response) {
    if (response is Map) return Map<String, dynamic>.from(response);
    if (response is List && response.isNotEmpty && response.first is Map) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    throw const FormatException(
      'The Admin dashboard response was empty or had an unexpected format.',
    );
  }

  List<Map<String, dynamic>> _rows(dynamic response) {
    if (response is! List) return const [];
    return response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }
}
