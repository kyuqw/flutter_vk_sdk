import '../vk_method_call.dart';

class Video {
  VKApiMethodCall save({
    String name,
    String description,
    bool isPrivate,
    bool wallpost,
    String link,
    int groupId,
    int albumId,
    String privacyView,
    String privacyComment,
    bool noComments,
    bool repeat,
    bool compression,
  }) {
    final callBuilder = VKApiMethodCall('video.save');
    callBuilder.setValue('name', name);
    callBuilder.setValue('description', description);
    callBuilder.setBool('is_private', isPrivate);
    callBuilder.setBool('wallpost', wallpost);
    callBuilder.setValue('link', link);
    callBuilder.setValue('group_id', groupId);
    callBuilder.setValue('album_id', albumId);
    callBuilder.setValue('privacy_view', privacyView);
    callBuilder.setValue('privacy_comment', privacyComment);
    callBuilder.setBool('no_comments', noComments);
    callBuilder.setBool('repeat', repeat);
    callBuilder.setBool('compression', compression);
    return callBuilder;
  }
}
