import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
//import 'package:flutter_vk_sdk/flutter_vk_sdk.dart';

void main() {
  const MethodChannel channel = MethodChannel('com.fb.fluttervksdk/vk');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

// TODO: write tests
//  test('getPlatformVersion', () async {
//    expect(await FlutterVKSdk.platformVersion, '42');
//  });
}
