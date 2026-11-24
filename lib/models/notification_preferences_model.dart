class NotificationPreferences {
  const NotificationPreferences({
    required this.userId,
    required this.inAppEnabled,
    required this.emailEnabled,
    required this.pushEnabled,
    required this.taskUpdates,
    required this.quoteUpdates,
    required this.messageUpdates,
    required this.deliveryUpdates,
    required this.projectUpdates,
    this.updatedAt,
  });

  final String userId;
  final bool inAppEnabled;
  final bool emailEnabled;
  final bool pushEnabled;
  final bool taskUpdates;
  final bool quoteUpdates;
  final bool messageUpdates;
  final bool deliveryUpdates;
  final bool projectUpdates;
  final DateTime? updatedAt;

  factory NotificationPreferences.defaults(String userId) {
    return NotificationPreferences(
      userId: userId,
      inAppEnabled: true,
      emailEnabled: false,
      pushEnabled: false,
      taskUpdates: true,
      quoteUpdates: true,
      messageUpdates: true,
      deliveryUpdates: true,
      projectUpdates: true,
    );
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      userId: _string(map['user_id']),
      inAppEnabled: _bool(map['in_app_enabled'], fallback: true),
      emailEnabled: _bool(map['email_enabled']),
      pushEnabled: _bool(map['push_enabled']),
      taskUpdates: _bool(map['task_updates'], fallback: true),
      quoteUpdates: _bool(map['quote_updates'], fallback: true),
      messageUpdates: _bool(map['message_updates'], fallback: true),
      deliveryUpdates: _bool(map['delivery_updates'], fallback: true),
      projectUpdates: _bool(map['project_updates'], fallback: true),
      updatedAt: _date(map['updated_at']),
    );
  }

  Map<String, dynamic> toUpsertMap() => {
        'user_id': userId,
        'in_app_enabled': inAppEnabled,
        'email_enabled': emailEnabled,
        'push_enabled': pushEnabled,
        'task_updates': taskUpdates,
        'quote_updates': quoteUpdates,
        'message_updates': messageUpdates,
        'delivery_updates': deliveryUpdates,
        'project_updates': projectUpdates,
      };

  NotificationPreferences copyWith({
    bool? inAppEnabled,
    bool? emailEnabled,
    bool? pushEnabled,
    bool? taskUpdates,
    bool? quoteUpdates,
    bool? messageUpdates,
    bool? deliveryUpdates,
    bool? projectUpdates,
    DateTime? updatedAt,
  }) {
    return NotificationPreferences(
      userId: userId,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      taskUpdates: taskUpdates ?? this.taskUpdates,
      quoteUpdates: quoteUpdates ?? this.quoteUpdates,
      messageUpdates: messageUpdates ?? this.messageUpdates,
      deliveryUpdates: deliveryUpdates ?? this.deliveryUpdates,
      projectUpdates: projectUpdates ?? this.projectUpdates,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get comparisonKey => toUpsertMap().entries
      .map((entry) => '${entry.key}:${entry.value}')
      .join('|');

  static String _string(dynamic value) => value?.toString() ?? '';

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'true' || normalized == 't' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == 'f' || normalized == '0') {
        return false;
      }
    }
    return fallback;
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
