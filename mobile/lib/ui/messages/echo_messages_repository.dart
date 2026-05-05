import 'package:dio/dio.dart';
import 'package:mobile/data/network/authenticated_api_client.dart';
import 'package:mobile/ui/messages/messages_repository.dart';

class EchoMessagesRepository implements MessagesRepository {
  EchoMessagesRepository({
    required String echoBaseUrl,
    required Future<String?> Function() getAccessToken,
    Future<String?> Function()? refreshAccessToken,
    Dio? dio,
  }) : _api = AuthenticatedApiClient(
         baseUrl: echoBaseUrl,
         getAccessToken: getAccessToken,
         refreshAccessToken: refreshAccessToken,
         onMissingToken: () => const MessagesAuthException('No active session'),
         dio: dio,
       );

  final AuthenticatedApiClient _api;

  Never _translateError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) {
      throw MessagesAuthException(e.message);
    }
    if (status == 403) {
      throw MessagesPermissionException(
        e.response?.data is Map<String, dynamic>
            ? (e.response?.data['detail'] as String?)
            : e.message,
      );
    }
    throw MessagesLoadException(e.message);
  }

  @override
  Future<List<MessageThreadSummary>> listThreads() async {
    try {
      final response = await _api.get(_api.path('/v1/messages/threads'));
      final raw = response.data as List<dynamic>? ?? const [];
      return raw
          .map((item) => item as Map<String, dynamic>)
          .map(
            (json) => MessageThreadSummary(
              userId: json['user_id'] as String,
              username: json['username'] as String,
              lastMessagePreview: json['last_message_preview'] as String,
              lastMessageAt: DateTime.parse(json['last_message_at'] as String),
            ),
          )
          .toList();
    } on DioException catch (e) {
      _translateError(e);
    }
  }

  @override
  Future<DirectMessageThread> getConversation(String userId) async {
    try {
      final response = await _api.get(_api.path('/v1/messages/$userId'));
      final json = response.data as Map<String, dynamic>;
      final rawItems = json['items'] as List<dynamic>? ?? const [];
      return DirectMessageThread(
        targetUserId: json['target_user_id'] as String,
        targetUsername: json['target_username'] as String,
        items: rawItems
            .map((item) => item as Map<String, dynamic>)
            .map(
              (item) => DirectMessage(
                id: item['id'] as String,
                senderUserId: item['sender_user_id'] as String,
                senderUsername: item['sender_username'] as String,
                text: item['text'] as String,
                createdAt: DateTime.parse(item['created_at'] as String),
                isMine: item['is_mine'] as bool? ?? false,
              ),
            )
            .toList(),
      );
    } on DioException catch (e) {
      _translateError(e);
    }
  }

  @override
  Future<DirectMessage> sendMessage(String userId, String text) async {
    try {
      final response = await _api.post(
        _api.path('/v1/messages/$userId'),
        data: {'text': text},
      );
      final item = response.data as Map<String, dynamic>;
      return DirectMessage(
        id: item['id'] as String,
        senderUserId: item['sender_user_id'] as String,
        senderUsername: item['sender_username'] as String,
        text: item['text'] as String,
        createdAt: DateTime.parse(item['created_at'] as String),
        isMine: item['is_mine'] as bool? ?? false,
      );
    } on DioException catch (e) {
      _translateError(e);
    }
  }
}
