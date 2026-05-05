import 'package:dio/dio.dart';
import 'package:mobile/data/network/authenticated_api_client.dart';
import 'package:mobile/ui/home/home_view_model.dart';
import 'package:mobile/ui/post/post_repository.dart';

class EchoPostRepository implements PostRepository {
  EchoPostRepository({
    required String echoBaseUrl,
    required Future<String?> Function() getAccessToken,
    Future<String?> Function()? refreshAccessToken,
    Dio? dio,
  }) : _api = AuthenticatedApiClient(
         baseUrl: echoBaseUrl,
         getAccessToken: getAccessToken,
         refreshAccessToken: refreshAccessToken,
         onMissingToken: () => const PostAuthException('No active session'),
         dio: dio,
       );

  final AuthenticatedApiClient _api;

  @override
  Future<void> createPost({
    required PostPrivacy privacy,
    String? text,
    String? spotifyUrl,
  }) async {
    final trimmedText = text?.trim();
    final trimmedSpotify = spotifyUrl?.trim();
    try {
      await _api.post(
        _api.path('/v1/posts'),
        data: <String, dynamic>{
          'privacy': _toApiPrivacy(privacy),
          if (trimmedText != null && trimmedText.isNotEmpty)
            'text': trimmedText,
          if (trimmedSpotify != null && trimmedSpotify.isNotEmpty)
            'spotify_url': trimmedSpotify,
        },
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) {
        throw PostAuthException(e.message);
      }
      throw PostCreateException(e.message);
    }
  }

  String _toApiPrivacy(PostPrivacy privacy) {
    switch (privacy) {
      case PostPrivacy.public:
        return 'Public';
      case PostPrivacy.friendsOnly:
        return 'Friends';
      case PostPrivacy.onlyMe:
        return 'OnlyMe';
    }
  }
}
