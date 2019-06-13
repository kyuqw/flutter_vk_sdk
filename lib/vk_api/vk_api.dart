import '../vk_method_call.dart';
import 'photos.dart';
import 'wall.dart';

class VkApi {
  VkApiMethodCall createMethodCall(String method) {
    assert(method?.isNotEmpty == true);
    return VkApiMethodCall(method);
  }

  final wall = Wall();
  final photos = Photos();
}
