import 'package:dio/dio.dart';
import 'package:mobile/data/network/authenticated_api_client.dart';
import 'package:mobile/ui/notifications/notifications_repository.dart';

class EchoNotificationsRepository implements NotificationsRepository {
  EchoNotificationsRepository({
    required String echoBaseUrl,
    required Future<String?> Function() getAccessToken,
    Future<String?> Function()? refreshAccessToken,
    Dio? dio,
  }) : _api = AuthenticatedApiClient(
         baseUrl: echoBaseUrl,
         getAccessToken: getAccessToken,
         refreshAccessToken: refreshAccessToken,
         onMissingToken: () =>
             const NotificationsAuthException('No active session'),
         dio: dio,
       );

  final AuthenticatedApiClient _api;

  Never _translateError(DioException e) {
    if (e.response?.statusCode == 401) {
      throw NotificationsAuthException(e.message);
    }
    throw NotificationsLoadException(e.message);
  }

  @override
  Future<List<FollowRequestNotification>> listIncomingFollowRequests() async {
    try {
      final response = await _api.get(
        _api.path('/v1/friends/requests/incoming'),
      );
      final raw = response.data as List<dynamic>? ?? const [];
      return raw
          .map((item) => item as Map<String, dynamic>)
          .map(
            (json) => FollowRequestNotification(
              requesterUserId: json['requester_user_id'] as String,
              requesterUsername: json['requester_username'] as String,
              requestedAt: DateTime.parse(json['requested_at'] as String),
            ),
          )
          .toList();
    } on DioException catch (e) {
      _translateError(e);
    }
  }

  @override
  Future<List<PostActivityNotification>> listPostActivityNotifications() async {
    try {
      final response = await _api.get(
        _api.path('/v1/notifications/post-activity'),
      );
      final raw = response.data as List<dynamic>? ?? const [];
      return raw
          .map((item) => item as Map<String, dynamic>)
          .map(
            (json) => PostActivityNotification(
              id: json['id'] as String,
              actorUserId: json['actor_user_id'] as String,
              actorUsername: json['actor_username'] as String? ?? 'Unknown',
              postId: json['post_id'] as String,
              activityType: json['activity_type'] as String? ?? 'like',
              commentPreview: json['comment_preview'] as String?,
              createdAt: DateTime.parse(json['created_at'] as String),
            ),
          )
          .toList(growable: false);
    } on DioException catch (e) {
      _translateError(e);
    }
  }

  @override
  Future<void> acceptFollowRequest(String requesterUserId) async {
    try {
      await _api.post(_api.path('/v1/friends/$requesterUserId/accept'));
    } on DioException catch (e) {
      _translateError(e);
    }
  }
}
