import 'dart:convert';

class WorkbridgeNotification {
  const WorkbridgeNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.actorId,
    this.entityType,
    this.entityId,
    this.readAt,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String recipientId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? actorId;
  final String? entityType;
  final String? entityId;
  final DateTime? readAt;
  final Map<String, dynamic> metadata;

  String get category {
    if (type.contains('quote') || type.contains('counteroffer')) return 'quotes';
    if (type == 'project_message_received') return 'messages';
    return 'projects';
  }

  WorkbridgeNotification copyWith({bool? isRead, DateTime? readAt}) {
    return WorkbridgeNotification(
      id: id,
      recipientId: recipientId,
      type: type,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      actorId: actorId,
      entityType: entityType,
      entityId: entityId,
      readAt: readAt ?? this.readAt,
      metadata: metadata,
    );
  }

  factory WorkbridgeNotification.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    Map<String, dynamic> parsedMetadata = const <String, dynamic>{};
    if (rawMetadata is Map) {
      parsedMetadata = Map<String, dynamic>.from(rawMetadata);
    } else if (rawMetadata is String && rawMetadata.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMetadata);
        if (decoded is Map) parsedMetadata = Map<String, dynamic>.from(decoded);
      } catch (_) {
        parsedMetadata = const <String, dynamic>{};
      }
    }

    return WorkbridgeNotification(
      id: _string(json['id']),
      recipientId: _string(json['recipient_id']),
      type: _string(json['notification_type']),
      title: _string(json['title']),
      body: _string(json['body']),
      isRead: json['is_read'] == true,
      createdAt: _date(json['created_at']) ?? DateTime.now(),
      actorId: _nullable(json['actor_id']),
      entityType: _nullable(json['entity_type']),
      entityId: _nullable(json['entity_id']),
      readAt: _date(json['read_at']),
      metadata: parsedMetadata,
    );
  }

  static String _string(dynamic value) => value?.toString().trim() ?? '';

  static String? _nullable(dynamic value) {
    final valueText = value?.toString().trim() ?? '';
    return valueText.isEmpty ? null : valueText;
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
