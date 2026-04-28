class NotificationActor {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? profileImage;

  const NotificationActor({
    required this.id,
    this.firstName,
    this.lastName,
    this.username,
    this.profileImage,
  });

  String get displayName {
    final full = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (full.isNotEmpty) return full;
    if (username != null && username!.trim().isNotEmpty) return username!.trim();
    return 'Someone';
  }

  static NotificationActor? fromJson(dynamic json) {
    if (json is! Map) return null;
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) return null;

    final profile = json['profile'];
    String? username;
    String? profileImage;
    if (profile is Map) {
      username = profile['username']?.toString();
      profileImage = profile['profileImage']?.toString();
    }

    return NotificationActor(
      id: id,
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      username: username,
      profileImage: profileImage,
    );
  }
}

class NotificationItem {
  final String id;
  final String type;
  final String? referenceId;
  final String? referenceType;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final bool isDelivered;
  final DateTime createdAt;
  final NotificationActor? actor;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.referenceId,
    this.referenceType,
    this.data,
    this.isRead = false,
    this.isDelivered = false,
    this.actor,
  });

  NotificationItem copyWith({
    bool? isRead,
    bool? isDelivered,
  }) {
    return NotificationItem(
      id: id,
      type: type,
      referenceId: referenceId,
      referenceType: referenceType,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      createdAt: createdAt,
      actor: actor,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    final raw = value?.toString();
    if (raw == null) return DateTime.now();
    return DateTime.tryParse(raw) ?? DateTime.now();
  }

  static NotificationItem? fromJson(dynamic json) {
    if (json is! Map) return null;
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) return null;

    return NotificationItem(
      id: id,
      type: (json['type'] ?? 'SYSTEM').toString(),
      referenceId: json['referenceId']?.toString(),
      referenceType: json['referenceType']?.toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : null,
      isRead: json['isRead'] == true,
      isDelivered: json['isDelivered'] == true,
      createdAt: _parseDate(json['createdAt']),
      actor: NotificationActor.fromJson(json['actor']),
    );
  }
}

