class ProjectChatMessage {
  const ProjectChatMessage({
    required this.id,
    required this.contractId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.attachmentPath,
    this.attachmentName,
    this.attachmentMimeType,
    this.attachmentSizeBytes,
  });

  final String id;
  final String contractId;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? attachmentPath;
  final String? attachmentName;
  final String? attachmentMimeType;
  final int? attachmentSizeBytes;

  bool get hasAttachment => attachmentPath != null && attachmentName != null;

  String get formattedAttachmentSize {
    final bytes = attachmentSizeBytes ?? 0;
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  factory ProjectChatMessage.fromJson(Map<String, dynamic> json) {
    return ProjectChatMessage(
      id: _string(json['id']),
      contractId: _string(json['contract_id']),
      senderId: _string(json['sender_id']),
      body: json['body']?.toString() ?? '',
      createdAt: _date(json['created_at']) ?? DateTime.now(),
      readAt: _date(json['read_at']),
      attachmentPath: _nullable(json['attachment_path']),
      attachmentName: _nullable(json['attachment_name']),
      attachmentMimeType: _nullable(json['attachment_mime_type']),
      attachmentSizeBytes: _intOrNull(json['attachment_size_bytes']),
    );
  }

  static String _string(dynamic value) => value?.toString().trim() ?? '';

  static String? _nullable(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
