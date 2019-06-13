import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'flutter_vk_sdk.dart';
import 'vk_response_parser.dart';

class VkMethodCall {
  String _channelMethod;
  final String endpoint;
  Map<String, String> _args = {};
  VkResponseParser parser;

  VkMethodCall(this.endpoint);

  MethodChannel get channel => FlutterVkSdk.channel;

  UnmodifiableMapView<String, String> get args => UnmodifiableMapView(_args);

  set args(Map<String, String> values) {
    if (values == null) return;
    final items = Map<String, String>();
    values.forEach((k, v) {
      if (!isEmptyKey(k) && !isEmptyKey(v)) items[k] = v;
    });
    _args.addAll(items);
  }

  setValue(String key, dynamic value) {
    final val = value is String ? value : value?.toString();
    if (isEmptyKey(key) || isEmptyValue(val)) return;
    _args[key] = val;
  }

  setBool(String key, bool value) {
    if (isEmptyValue(key) || value == null) return;
    _args[key] = (value ? 1 : 0).toString();
  }

  bool isEmptyKey(String value) {
    return value?.isNotEmpty != true;
  }

  bool isEmptyValue(String value) {
    return value?.isNotEmpty != true;
  }

  String getEndpoint() {
    assert(endpoint?.isNotEmpty == true);
    return endpoint;
  }

  String getChannelMethod() {
    assert(_channelMethod?.isNotEmpty == true);
    return _channelMethod;
  }

  Map<String, dynamic> getChannelArguments() {
    return _args;
  }

  dynamic parse(response, VkResponseParser parser) {
    final p = parser ?? this.parser;
    if (p == null) return response;
    return p.parse(response);
  }

  Future callMethod([dynamic arguments]) {
    return channel.invokeMethod(getChannelMethod(), arguments);
  }

  Future executeSync({VkResponseParser parser}) async {
    // TODO catch errors
    final response = await callMethod(getChannelArguments());
    return parse(response, parser);
  }

  execute({@required Function onSuccess, @required Function onError, VkResponseParser parser}) async {
    assert(onSuccess != null);
    assert(onError != null);
    try {
      final res = await executeSync(parser: parser);
      onSuccess(res);
    } on PlatformException catch (e) {
      onError(e);
    }
  }
}

class VkApiMethodCall extends VkMethodCall {
  final _methodStr = 'method';
  final _argumentsStr = 'arguments';
  final _retryCountStr = 'retry_count';
  final _skipValidationStr = 'skip_validation';
  String _channelMethod = 'api_method_call';
  int retryCount = 3;
  bool skipValidation;
  VkResponseParser parser = VkApiResponseParser();

  VkApiMethodCall(String method) : super(method);

  @override
  Map<String, dynamic> getChannelArguments() {
    final Map<String, dynamic> res = {_methodStr: getEndpoint()};
    if (_args?.isNotEmpty == true) res[_argumentsStr] = _args;
    if (retryCount != null) res[_retryCountStr] = retryCount;
    if (skipValidation != null) res[_skipValidationStr] = skipValidation;
    return res;
  }
}

class VkPostMethodCall extends VkMethodCall {
  final _urlStr = 'url';
  final _argumentsStr = 'arguments';
  final _retryCountStr = 'retry_count';
  final _timeoutStr = 'timeout';
  String _channelMethod = 'post_method_call';
  int retryCount = 3;

  /// [timeout] request timeout in milliseconds
  int timeout;
  VkResponseParser parser = VkApiResponseParser();

  VkPostMethodCall(String url) : super(url);

  @override
  Map<String, dynamic> getChannelArguments() {
    final Map<String, dynamic> res = {_urlStr: getEndpoint()};
    if (_args?.isNotEmpty == true) res[_argumentsStr] = _args;
    if (retryCount != null) res[_retryCountStr] = retryCount;
    if (timeout != null) res[_timeoutStr] = timeout;
    return res;
  }
}
