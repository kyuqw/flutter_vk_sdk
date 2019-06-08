import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:flutter_vk_sdk/vk_scope.dart';

class FlutterVkSdk {
  static const MethodChannel _channel = const MethodChannel('com.fb.fluttervksdk/vk');
  static final String _defaultScope = '${VkScope.email}, ${VkScope.notifications}';

  static Map<String, dynamic> _cast(Map items) {
    return items?.cast<String, dynamic>();
  }

  static Future<Map> init({String appId, String apiVersion}) async {
    // TODO apiVersion for iOS
    final Map init = await _channel.invokeMethod('initialize', {'app_id': appId, 'api_verson': apiVersion});
    return init;
  }

  static Future login({
    String scope,
    @required Function(Map<String, dynamic>) onSuccess,
    @required Function(PlatformException) onError,
  }) async {
    assert(onSuccess != null);
    assert(onError != null);
    try {
      if (scope == null || scope.isEmpty) scope = _defaultScope;
      final Map login = await _channel.invokeMethod('login', {'scope': scope});
      onSuccess(_cast(login));
    } on PlatformException catch (e) {
      onError(e);
    }
  }

  static Future logout() async {
    return _channel.invokeMethod('logout');
  }

  static Future<Map<String, dynamic>> getAccessToken() async {
    final Map token = await _channel.invokeMethod('get_access_token');
    return _cast(token);
  }

  static void share({
    String text,
    @required Function(String) onSuccess,
    @required Function(PlatformException) onError,
  }) async {
    assert(onSuccess != null);
    assert(onError != null);
    try {
      final postId = await _channel.invokeMethod('share', {'text': text});
      onSuccess(postId);
    } on PlatformException catch (e) {
      onError(e);
    }
  }

  static Future<bool> isLoggedIn() async {
    return await _channel.invokeMethod<bool>('is_logged_in');
  }
}
