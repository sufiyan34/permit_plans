import 'package:intl/intl.dart';

class ProjectDeliveryFile {
  const ProjectDeliveryFile({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.storagePath,
  });

  final String id;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String storagePath;

  String get formattedSize {
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (sizeBytes >= 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$sizeBytes B';
  }

  factory ProjectDeliveryFile.fromJson(Map<String, dynamic> json) {
    return ProjectDeliveryFile(
      id: _string(json['id']),
      fileName: _string(json['file_name'], fallback: 'Delivery file'),
      mimeType: _string(json['mime_type']),
      sizeBytes: _int(json['size_bytes']),
      storagePath: _string(json['storage_path']),
    );
  }

  static String _string(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ProjectDeliveryModel {
  const ProjectDeliveryModel({
    required this.deliveryId,
    required this.contractId,
    required this.submissionNumber,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.files,
    this.reviewedAt,
    this.reviewNote,
  });

  final String deliveryId;
  final String contractId;
  final int submissionNumber;
  final String message;
  final String status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final List<ProjectDeliveryFile> files;

  String get formattedDate =>
      DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toLocal());

  String get statusLabel {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'revision_requested':
        return 'Revision requested';
      case 'approved':
        return 'Approved';
      case 'superseded':
        return 'Previous version';
      default:
        return 'Delivery update';
    }
  }

  factory ProjectDeliveryModel.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'];
    final files = rawFiles is List
        ? rawFiles
            .whereType<Map>()
            .map((item) => ProjectDeliveryFile.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false)
        : const <ProjectDeliveryFile>[];

    return ProjectDeliveryModel(
      deliveryId: _string(json['delivery_id']),
      contractId: _string(json['contract_id']),
      submissionNumber: _int(json['submission_number']),
      message: _string(json['message']),
      status: _string(json['delivery_status']),
      createdAt: _date(json['created_at']) ?? DateTime.now(),
      reviewedAt: _date(json['reviewed_at']),
      reviewNote: _nullable(json['review_note']),
      files: files,
    );
  }

  static String _string(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullable(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
