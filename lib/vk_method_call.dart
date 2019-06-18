import 'dart:collection';
import 'dart:convert' show utf8;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'flutter_vk_sdk.dart';
import 'vk_response_parser.dart';

class VKMethodCall {
  String _channelMethod;
  final String endpoint;
  Map<String, String> _args = {};
  VKResponseParser parser;

  VKMethodCall(this.endpoint);

  MethodChannel get channel => FlutterVKSdk.channel;

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

  dynamic parse(response, VKResponseParser parser) {
    final p = parser ?? this.parser;
    if (p == null) return response;
    return p.parse(response);
  }

  Future callMethod([dynamic arguments]) {
    return channel.invokeMethod(getChannelMethod(), arguments);
  }

  Future executeSync({VKResponseParser parser}) async {
    // TODO catch errors
    final response = await callMethod(getChannelArguments());
    return parse(response, parser);
  }

  execute({@required Function onSuccess, @required Function onError, VKResponseParser parser}) async {
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

class VKApiMethodCall extends VKMethodCall {
  final _methodStr = 'method';
  final _argumentsStr = 'arguments';
  final _retryCountStr = 'retry_count';
  final _skipValidationStr = 'skip_validation';
  String _channelMethod = 'api_method_call';
  int retryCount = 3;
  bool skipValidation;
  VKResponseParser parser = VKApiResponseParser();

  VKApiMethodCall(String method) : super(method);

  @override
  Map<String, dynamic> getChannelArguments() {
    final Map<String, dynamic> res = {_methodStr: getEndpoint()};
    if (_args?.isNotEmpty == true) res[_argumentsStr] = _args;
    if (retryCount != null) res[_retryCountStr] = retryCount;
    if (skipValidation != null) res[_skipValidationStr] = skipValidation;
    return res;
  }
}

class VKPostMethodCall extends VKMethodCall {
  final _urlStr = 'url';
  final _argumentsStr = 'arguments';
  final _retryCountStr = 'retry_count';
  final _timeoutStr = 'timeout';
  String _channelMethod = 'post_method_call';
  int retryCount = 3;

  /// [timeout] request timeout in milliseconds
  int timeout;
  VKResponseParser parser = VKApiResponseParser();

  VKPostMethodCall(String url) : super(url);

  @override
  Map<String, dynamic> getChannelArguments() {
    final Map<String, dynamic> res = {_urlStr: getEndpoint()};
    if (_args?.isNotEmpty == true) res[_argumentsStr] = _args;
    if (retryCount != null) res[_retryCountStr] = retryCount;
    if (timeout != null) res[_timeoutStr] = timeout;
    return res;
  }

  @override
  Future callMethod([arguments]) {
    return InternalErrorRetryChainCall(this).executeAsync();
  }
}

class InternalErrorRetryChainCall {
  final VKPostMethodCall postCall;

  InternalErrorRetryChainCall(this.postCall);

  Future<String> executeAsync() async {
    final request = http.MultipartRequest('POST', Uri.parse(postCall.getEndpoint()));
    final args = postCall.args;
    if (args != null) {
      for (var item in args.entries) {
        final path = Uri.parse(item.value).path;
        final file = await http.MultipartFile.fromPath(item.key, path);
        request.files.add(file);
      }
    }
    Duration timeLimit;
    if (postCall.timeout != null) timeLimit = Duration(milliseconds: postCall.timeout);
    // TODO: cancel request on timeout
    final response = await (timeLimit == null ? request.send() : request.send().timeout(timeLimit));
    if (response.statusCode != 200) return null;
    final bodyContent = await utf8.decodeStream(response.stream);
    return bodyContent;
  }
}
