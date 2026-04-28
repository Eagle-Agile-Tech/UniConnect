class NotificationActor {
  const NotificationActor({
    required this.id,
    this.firstName,
    this.lastName,
    this.username,
    this.profileImage,
  });

  final String id;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? profileImage;

  String get displayName {
    final fullName = [firstName, lastName]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' ');
    if (fullName.isNotEmpty) {
      return fullName;
    }
    final uname = username?.trim();
    if (uname != null && uname.isNotEmpty) {
      return '@$uname';
    }
    return 'Someone';
  }

  factory NotificationActor.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final profileMap = profile is Map
        ? Map<String, dynamic>.from(profile)
        : const <String, dynamic>{};
    return NotificationActor(
      id: (json['id'] ?? '').toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      username: profileMap['username']?.toString(),
      profileImage: profileMap['profileImage']?.toString(),
    );
  }
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.recipientId,
    this.actorId,
    required this.type,
    this.referenceId,
    this.referenceType,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.isDelivered,
    required this.createdAt,
    required this.updatedAt,
    this.actor,
  });

  final String id;
  final String recipientId;
  final String? actorId;
  final String type;
  final String? referenceId;
  final String? referenceType;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final bool isDelivered;
  final DateTime createdAt;
  final DateTime updatedAt;
  final NotificationActor? actor;

  NotificationItem copyWith({
    bool? isRead,
    bool? isDelivered,
  }) {
    return NotificationItem(
      id: id,
      recipientId: recipientId,
      actorId: actorId,
      type: type,
      referenceId: referenceId,
      referenceType: referenceType,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      createdAt: createdAt,
      updatedAt: updatedAt,
      actor: actor,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final rawActor = json['actor'];

    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      recipientId: (json['recipientId'] ?? '').toString(),
      actorId: json['actorId']?.toString(),
      type: (json['type'] ?? '').toString(),
      referenceId: json['referenceId']?.toString(),
      referenceType: json['referenceType']?.toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      data: rawData is Map ? Map<String, dynamic>.from(rawData) : null,
      isRead: json['isRead'] == true,
      isDelivered: json['isDelivered'] == true,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      actor: rawActor is Map
          ? NotificationActor.fromJson(Map<String, dynamic>.from(rawActor))
          : null,
    );
  }
}

class NotificationFeed {
  const NotificationFeed({
    required this.notifications,
    required this.unreadCount,
  });

  final List<NotificationItem> notifications;
  final int unreadCount;
}
