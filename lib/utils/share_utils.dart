import 'package:meta/meta.dart';
import 'package:flutter/services.dart';

import '../flutter_vk_sdk.dart';
import '../vk_method_call.dart';
import '../models/attachment.dart';

class Share {
  var wallUploadServer;

  execute({
    @required Function onSuccess,
    @required Function onError,
    int ownerId,
    String message,
    List<Attachment> attachments,
    bool fromGroup,
    bool friendsOnly,
    bool closeComments,
    bool muteNotifications,
  }) async {
    try {
      String attachmentsStr = await getAttachments(attachments);

      FlutterVkSdk.api.wall
          .post(
              ownerId: ownerId,
              message: message,
              attachments: attachmentsStr,
              fromGroup: fromGroup,
              friendsOnly: friendsOnly,
              closeComments: closeComments,
              muteNotifications: muteNotifications)
          .execute(onSuccess: onSuccess, onError: onError);
    } on PlatformException catch (e) {
      onError(e);
    }
  }

  getWallUploadServer() async {
    if (wallUploadServer == null) {
      wallUploadServer = FlutterVkSdk.api.photos.getWallUploadServer().executeSync();
    }
    assert(wallUploadServer != null);
    return wallUploadServer;
  }

  Future<String> getAttachments(List<Attachment> attachments) async {
    if (attachments == null || attachments.isEmpty) return null;
    List<String> attachmentsStr = [];
    for (var i = 0; i < attachments.length; i++) {
      final a = attachments[i];
      String value;
      switch (a.type) {
        case AttachmentType.photo:
          value = await uploadPhoto(a.value);
          break;
        case AttachmentType.url:
          value = a.value;
          break;
      }
      if (value?.isNotEmpty == true) attachmentsStr.add(value);
    }
    if (attachmentsStr.isEmpty) return null;
    return attachmentsStr.join(',');
  }

  Future<String> uploadPhoto(String source) async {
    final uploadServer = await getWallUploadServer();
    final saveInfo = await PhotoUploader(wallUploadServer: uploadServer).uploadWallPhoto(source);
    final ownerId = saveInfo['owner_id'];
    final id = saveInfo['id'];
    return 'photo${ownerId}_$id';
  }
}

class PhotoUploader {
  var wallUploadServer;

  PhotoUploader({this.wallUploadServer});

  getWallUploadServer() async {
    if (wallUploadServer == null) {
      wallUploadServer = FlutterVkSdk.api.photos.getWallUploadServer().executeSync();
    }
    assert(wallUploadServer != null);
    return wallUploadServer;
  }

  Future uploadWallPhoto(String source) async {
    final uploadServer = await getWallUploadServer();
    final uploadBuilder = VkPostMethodCall(uploadServer['upload_url']);
    uploadBuilder.setValue('photo', getFileUri(source));
    var fileInfo = await uploadBuilder.executeSync();
    if (fileInfo is List) fileInfo = fileInfo[0];
    var saveInfo = await FlutterVkSdk.api.photos
        .saveWallPhoto(server: fileInfo['server'], photo: fileInfo['photo'], hash: fileInfo['hash'])
        .executeSync();
    if (saveInfo is List) saveInfo = saveInfo[0];
    return saveInfo;
  }

  String getFileUri(String source) {
    source = source?.toLowerCase();
    if (source == null || source.startsWith('file:///')) return source;
    return Uri.file(source).toString();
  }
}
