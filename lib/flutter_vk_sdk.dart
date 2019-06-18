import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'models/attachment.dart';
import 'models/vk_access_token.dart';
import 'ui/vk_share_page.dart';
import 'vk_api/vk_api.dart';

class FlutterVKSdk {
  static final String _defaultScope = null;
  static const MethodChannel channel = const MethodChannel('com.fb.fluttervksdk/vk');
  static final api = VKApi();

  static Map<String, dynamic> _cast(Map items) {
    return items?.cast<String, dynamic>();
  }

  static Future<Map> init({String appId, String apiVersion}) async {
    if (Platform.isIOS) {
      // TODO apiVersion for iOS
      final Map init = await channel.invokeMethod('initialize', {'app_id': appId, 'api_verson': apiVersion});
      return init;
    }
    return null;
  }

  static Future<bool> isLoggedIn() async {
    return await channel.invokeMethod<bool>('is_logged_in');
  }

  static Future<VKAccessToken> getAccessToken() async {
    final Map token = await channel.invokeMethod('get_access_token');
    return VKAccessToken.fromJson(_cast(token));
  }

  static Future login({
    String scope,
    @required Function(VKAccessToken) onSuccess,
    @required Function(PlatformException) onError,
  }) async {
    assert(onSuccess != null);
    assert(onError != null);
    try {
      if (scope == null || scope.isEmpty) scope = _defaultScope;
      final Map login = await channel.invokeMethod('login', {'scope': scope});
      onSuccess(VKAccessToken.fromJson(_cast(login)));
    } on PlatformException catch (e) {
      onError(e);
    }
  }

  static Future logout() async {
    return channel.invokeMethod('logout');
  }

  static shareWithDialog({
    @required BuildContext context,
    @required Function(String) onSuccess,
    @required Function(PlatformException) onError,
    String text,
    List attachments,
    Future<List> Function(AttachmentType) addAttachments,
  }) {
    assert(onSuccess != null);
    assert(onError != null);
    return VKSharePage.show(
      context: context,
      onSuccess: onSuccess,
      onError: onError,
      text: text,
      attachments: attachments,
      addAttachmentsDelegate: addAttachments,
    );
  }
}
