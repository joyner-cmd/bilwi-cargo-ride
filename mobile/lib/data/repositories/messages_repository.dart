import '../../core/network/api_client.dart';
import '../models/message.dart';

class MessagesRepository {
  MessagesRepository(this._api);
  final ApiClient _api;

  Future<List<ChatMessage>> history(int tripId) async {
    final res = await _api.dio.get('/messages/$tripId');
    return (res.data['messages'] as List)
        .map((e) => ChatMessage.fromJson(e))
        .toList();
  }

  Future<ChatMessage> send(int tripId, String body) async {
    final res = await _api.dio.post('/messages/$tripId', data: {'body': body});
    return ChatMessage.fromJson(res.data);
  }
}
