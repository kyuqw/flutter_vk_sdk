import '../vk_method_call.dart';

class Photos {
  VKApiMethodCall getWallUploadServer({int groupId}) {
    final callBuilder = VKApiMethodCall('photos.getWallUploadServer');
    callBuilder.setValue('group_id', groupId);
    return callBuilder;
  }

  VKApiMethodCall saveWallPhoto({
    int userId,
    int groupId,
    String photo,
    int server,
    String hash,
    double latitude,
    double longitude,
    String caption,
  }) {
    final callBuilder = VKApiMethodCall('photos.saveWallPhoto');
    callBuilder.setValue('user_id', groupId);
    callBuilder.setValue('group_id', groupId);
    callBuilder.setValue('photo', photo);
    callBuilder.setValue('server', server);
    callBuilder.setValue('hash', hash);
    callBuilder.setValue('latitude', latitude);
    callBuilder.setValue('longitude', longitude);
    callBuilder.setValue('caption', caption);
    return callBuilder;
  }
}
