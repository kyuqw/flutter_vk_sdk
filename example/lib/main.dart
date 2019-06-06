import 'package:flutter/material.dart';
import 'package:flutter_vk_sdk/flutter_vk_sdk.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _value = 'unknown';

  @override
  void initState() {
    super.initState();
    vkLogin();
  }

  void vkLogin() {
    FlutterVkSdk.login(
      onSuccess: (res) {
        setState(() {
          _value = 'true';
        });
      },
      onError: (error) {
        setState(() {
          _value = 'error';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('LoggedIn: $_value\n'),
        ),
      ),
    );
  }
}
