import 'package:flutter/material.dart';
import 'package:flutter_vk_sdk/flutter_vk_sdk.dart';

void main() {
  initVkSdk();
  runApp(MyApp());
}

initVkSdk() async {
  return await FlutterVkSdk.init(appId: '5555555');
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _value = 'unknown';

  @override
  void initState() {
    super.initState();
  }

  checkLoggedIn() async {
    var isLoggedIn = await FlutterVkSdk.isLoggedIn();
    setState(() {
      _value = isLoggedIn.toString();
    });
  }

  void vkLogin() async {
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

  vkShare() async {
    var i = await FlutterVkSdk.init(appId: '5555555');
    print(i);
    FlutterVkSdk.share(
      text: "Я участник форума #YTPO2019",
      onSuccess: (res) {
        print('SUCCESS: $res}');
        setState(() {
          _value = 'true';
        });
      },
      onError: (error) {
        print('ERROR: $error}');
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
          leading: FlatButton(
            onPressed: vkLogin,
            child: Icon(Icons.input),
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: vkShare,
              child: Icon(Icons.share),
            )
          ],
        ),
        body: Center(
          child: Text('LoggedIn: $_value\n'),
        ),
      ),
    );
  }
}
