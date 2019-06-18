import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../flutter_vk_sdk.dart';
import '../vk_method_call.dart';
import '../models/attachment.dart';

String getFileUri(String source) {
  if (source == null || source.toLowerCase().startsWith('file:///')) return source;
  return Uri.file(source).toString();
}

class Share {
  var wallUploadServer;

  int ownerId;
  String message;
  List<Attachment> attachments;
  bool fromGroup;
  bool friendsOnly;
  bool closeComments;
  bool muteNotifications;

  Share({
    this.ownerId,
    this.message,
    this.attachments,
    this.fromGroup,
    this.friendsOnly,
    this.closeComments,
    this.muteNotifications,
  });

  execute({
    @required Function onSuccess,
    @required Function onError,
  }) async {
    try {
      String attachmentsStr = await getAttachments(attachments);

      FlutterVKSdk.api.wall
          .post(
            ownerId: ownerId,
            message: message,
            attachments: attachmentsStr,
            fromGroup: fromGroup,
            friendsOnly: friendsOnly,
            closeComments: closeComments,
            muteNotifications: muteNotifications,
          )
          .execute(onSuccess: onSuccess, onError: onError);
    } on PlatformException catch (e) {
      onError(e);
    } catch (e) {
      onError(e);
    }
  }

  getWallUploadServer() async {
    if (wallUploadServer == null) {
      wallUploadServer = FlutterVKSdk.api.photos.getWallUploadServer().executeSync();
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
        case AttachmentType.video:
          value = await uploadVideo(a.value);
          break;
        case AttachmentType.url:
          value = a.value;
          break;
        default:
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

  Future<String> uploadVideo(String source) async {
    final saveInfo = await VideoUploader().uploadVideo(source);
    final ownerId = saveInfo['owner_id'];
    final videoId = saveInfo['video_id'];
    return 'video${ownerId}_$videoId';
  }
}

class PhotoUploader {
  var _wallUploadServer;

  PhotoUploader({wallUploadServer}) : _wallUploadServer = wallUploadServer;

  getWallUploadServer() async {
    if (_wallUploadServer == null) {
      _wallUploadServer = FlutterVKSdk.api.photos.getWallUploadServer().executeSync();
    }
    assert(_wallUploadServer != null);
    return _wallUploadServer;
  }

  Future uploadWallPhoto(String source) async {
    final uploadServer = await getWallUploadServer();
    final uploadBuilder = VKPostMethodCall(uploadServer['upload_url']);
    uploadBuilder.setValue('photo', getFileUri(source));
    var fileInfo = await uploadBuilder.executeSync();
    if (fileInfo is List) fileInfo = fileInfo[0];
    var saveInfo = await FlutterVKSdk.api.photos
        .saveWallPhoto(server: fileInfo['server'], photo: fileInfo['photo'], hash: fileInfo['hash'])
        .executeSync();
    if (saveInfo is List) saveInfo = saveInfo[0];
    return saveInfo;
  }
}

class VideoUploader {
  var _uploadServer;

  VideoUploader({uploadServer}) : _uploadServer = uploadServer;

  getUploadServer() async {
    if (_uploadServer == null) {
      _uploadServer = FlutterVKSdk.api.video.save().executeSync();
    }
    assert(_uploadServer != null);
    return _uploadServer;
  }

  Future uploadVideo(String source) async {
    final uploadServer = await getUploadServer();
    final uploadBuilder = VKPostMethodCall(uploadServer['upload_url']);
    uploadBuilder.setValue('video_file', getFileUri(source));
    var fileInfo = await uploadBuilder.executeSync();
    if (fileInfo is List) fileInfo = fileInfo[0];
    return fileInfo;
  }
}
