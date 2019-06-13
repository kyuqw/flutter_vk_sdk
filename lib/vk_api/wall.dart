import '../vk_method_call.dart';

class Wall {
  VkApiMethodCall post({
    int ownerId,
    String message,
    String attachments,
    bool fromGroup,
    bool friendsOnly,
    bool closeComments,
    bool muteNotifications,
  }) {
    final callBuilder = VkApiMethodCall('wall.post');
    callBuilder.setValue('owner_id', ownerId);
    callBuilder.setValue('message', message);
    callBuilder.setValue('attachments', attachments);
    callBuilder.setBool('friends_only', friendsOnly);
    callBuilder.setBool('from_group', fromGroup);
    callBuilder.setBool('close_comments', closeComments);
    callBuilder.setBool('mute_notifications', muteNotifications);
    return callBuilder;
  }
}
