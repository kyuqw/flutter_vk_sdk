import '../vk_method_call.dart';
import 'photos.dart';
import 'video.dart';
import 'wall.dart';

class VKApi {
  VKApiMethodCall createMethodCall(String method) {
    assert(method?.isNotEmpty == true);
    return VKApiMethodCall(method);
  }

  final photos = Photos();
  final video = Video();
  final wall = Wall();
}
