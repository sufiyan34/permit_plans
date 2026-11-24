import 'package:intl/intl.dart';

/// A task invitation sent directly by a Client to the signed-in Engineer.
/// Values are returned by the restricted get_my_task_invitations RPC.
class EngineerTaskInvitation {
  const EngineerTaskInvitation({
    required this.invitationId,
    required this.taskId,
    required this.clientId,
    required this.clientName,
    required this.invitationStatus,
    required this.sentAt,
    required this.title,
    required this.description,
    required this.category,
    required this.requiredSkills,
    required this.currency,
    required this.taskStatus,
    required this.attachmentCount,
    this.clientCountryName,
    this.clientAvatarUrl,
    this.budgetMinMinor,
    this.budgetMaxMinor,
    this.deadlineAt,
  });

  final String invitationId;
  final String taskId;
  final String clientId;
  final String clientName;
  final String invitationStatus;
  final DateTime sentAt;
  final String title;
  final String description;
  final String category;
  final List<String> requiredSkills;
  final String currency;
  final String taskStatus;
  final int attachmentCount;
  final String? clientCountryName;
  final String? clientAvatarUrl;
  final int? budgetMinMinor;
  final int? budgetMaxMinor;
  final DateTime? deadlineAt;

  String get clientInitials {
    final parts = clientName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'C';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get sentAtLabel => DateFormat('MMM d, y').format(sentAt.toLocal());

  String get deadlineLabel => deadlineAt == null
      ? 'No deadline specified'
      : DateFormat('MMM d, y').format(deadlineAt!.toLocal());

  String get budgetLabel {
    if (budgetMinMinor == null && budgetMaxMinor == null) {
      return 'Budget not specified';
    }
    final decimals = _fractionDigits(currency);
    final formatter = NumberFormat.currency(
      name: currency,
      decimalDigits: decimals,
    );
    final divisor = _minorUnitDivisor(decimals);
    final min = budgetMinMinor == null ? null : budgetMinMinor! / divisor;
    final max = budgetMaxMinor == null ? null : budgetMaxMinor! / divisor;

    if (min != null && max != null) {
      return '${formatter.format(min)} – ${formatter.format(max)}';
    }
    if (min != null) return 'From ${formatter.format(min)}';
    return 'Up to ${formatter.format(max)}';
  }

  factory EngineerTaskInvitation.fromMap(Map<String, dynamic> map) {
    return EngineerTaskInvitation(
      invitationId: _string(map['invitation_id']),
      taskId: _string(map['task_id']),
      clientId: _string(map['client_id']),
      clientName: _nonEmpty(map['client_name'], fallback: 'Marketplace client'),
      clientCountryName: _nullableString(map['client_country_name']),
      clientAvatarUrl: _nullableString(map['client_avatar_url']),
      invitationStatus: _string(map['invitation_status'], fallback: 'pending'),
      sentAt: DateTime.tryParse(_string(map['sent_at']))?.toLocal() ?? DateTime.now(),
      title: _string(map['task_title'], fallback: 'Untitled task'),
      description: _string(map['task_description']),
      category: _string(map['task_category'], fallback: 'Other'),
      requiredSkills: _stringList(map['required_skills']),
      currency: _string(map['currency'], fallback: 'USD').toUpperCase(),
      budgetMinMinor: (map['budget_min_minor'] as num?)?.toInt(),
      budgetMaxMinor: (map['budget_max_minor'] as num?)?.toInt(),
      deadlineAt: _parseDate(map['deadline_at']),
      taskStatus: _string(map['task_status'], fallback: 'invitation_pending'),
      attachmentCount: (map['attachment_count'] as num?)?.toInt() ?? 0,
    );
  }

  static String _string(dynamic value, {String fallback = ''}) =>
      value == null ? fallback : value.toString();

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    return parsed?.toLocal();
  }

  static String _nonEmpty(dynamic value, {required String fallback}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static int _fractionDigits(String currency) {
    if (const {'JPY', 'KRW'}.contains(currency)) return 0;
    if (const {'BHD', 'KWD', 'OMR', 'JOD'}.contains(currency)) return 3;
    return 2;
  }

  static num _minorUnitDivisor(int decimals) {
    if (decimals == 0) return 1;
    if (decimals == 3) return 1000;
    return 100;
  }
}

