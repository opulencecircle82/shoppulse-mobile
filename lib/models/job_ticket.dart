class JobTicket {
  final String id;
  final String clientName;
  final String serviceAddress;
  final String serviceType;
  final String status;
  final String? startPhotoUrl;
  final String? endPhotoUrl;
  final List<String> startChecklist;
  final List<String> endChecklist;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const JobTicket({
    required this.id,
    required this.clientName,
    required this.serviceAddress,
    required this.serviceType,
    required this.status,
    required this.startPhotoUrl,
    required this.endPhotoUrl,
    required this.startChecklist,
    required this.endChecklist,
    required this.startedAt,
    required this.completedAt,
  });

  factory JobTicket.fromJson(Map<String, dynamic> json) {
    return JobTicket(
      id: json['id'] as String,
      clientName: json['client_name'] as String? ?? '',
      serviceAddress: json['service_address'] as String? ?? '',
      serviceType: json['service_type'] as String? ?? '',
      status: json['status'] as String? ?? 'UNASSIGNED',
      startPhotoUrl: json['start_photo_url'] as String?,
      endPhotoUrl: json['end_photo_url'] as String?,
      startChecklist: _parseChecklist(json['start_checklist']),
      endChecklist: _parseChecklist(json['end_checklist']),
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
    );
  }

  static List<String> _parseChecklist(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }
}
