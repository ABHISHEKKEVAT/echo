import 'package:dio/dio.dart';
import 'package:mobile/data/network/authenticated_api_client.dart';
import 'package:mobile/ui/friends/friends_repository.dart';

class EchoFriendsRepository implements FriendsRepository {
  EchoFriendsRepository({
    required String echoBaseUrl,
    required Future<String?> Function() getAccessToken,
    Future<String?> Function()? refreshAccessToken,
    Dio? dio,
  }) : _api = AuthenticatedApiClient(
         baseUrl: echoBaseUrl,
         getAccessToken: getAccessToken,
         refreshAccessToken: refreshAccessToken,
         onMissingToken: () => const FriendsAuthException('No active session'),
         dio: dio,
       );

  final AuthenticatedApiClient _api;

  Never _translateError(DioException e) {
    if (e.response?.statusCode == 401) {
      throw FriendsAuthException(e.message);
    }
    throw FriendsLoadException(e.message);
  }

  @override
  Future<List<FriendListItem>> listFriends(FriendListType type) async {
    try {
      final path = switch (type) {
        FriendListType.followers => _api.path('/v1/friends/followers'),
        FriendListType.following => _api.path('/v1/friends/following'),
      };
      final response = await _api.get(path);
      final raw = response.data as List<dynamic>? ?? const [];
      return raw
          .map((item) => item as Map<String, dynamic>)
          .map(
            (json) => FriendListItem(
              userId: json['user_id'] as String,
              username: json['username'] as String,
              avatarUrl: json['avatar_url'] as String?,
            ),
          )
          .toList();
    } on DioException catch (e) {
      _translateError(e);
    }
  }
}
