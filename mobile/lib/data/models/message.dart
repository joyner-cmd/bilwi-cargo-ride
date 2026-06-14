class ChatMessage {
  ChatMessage({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.type,
    this.body,
    this.lat,
    this.lng,
    this.senderName,
    this.createdAt,
  });

  final int id;
  final int tripId;
  final int senderId;
  final String type;
  final String? body;
  final double? lat;
  final double? lng;
  final String? senderName;
  final DateTime? createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as int,
        tripId: j['trip_id'] as int,
        senderId: j['sender_id'] as int,
        type: (j['type'] ?? 'text') as String,
        body: j['body'] as String?,
        lat: j['lat'] == null ? null : (j['lat'] as num).toDouble(),
        lng: j['lng'] == null ? null : (j['lng'] as num).toDouble(),
        senderName: j['sender_name'] as String?,
        createdAt:
            j['created_at'] == null ? null : DateTime.tryParse('${j['created_at']}'),
      );
}
