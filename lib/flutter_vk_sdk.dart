import 'dart:async';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';

class FlutterVkSdk {
  static const MethodChannel _channel = const MethodChannel('com.fb.fluttervksdk/vk');

  static Map<String, dynamic> _cast(Map items) {
    return items?.cast<String, dynamic>();
  }

  static Future login({
    String scope,
    @required Function(Map<String, dynamic>) onSuccess,
    @required Function(PlatformException) onError,
  }) async {
    assert(onSuccess != null);
    assert(onError != null);
    try {
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
    @required Function(int) onSuccess,
    @required Function(PlatformException) onError,
    String loginScope,
  }) async {
    assert(onSuccess != null);
    assert(onError != null);
    try {
      final postId = await _channel.invokeMethod('share', {'text': text, 'scope': loginScope});
      onSuccess(postId);
    } on PlatformException catch (e) {
      onError(e);
    }
  }
}
