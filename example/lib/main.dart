import 'package:flutter/material.dart';
import 'package:flutter_vk_sdk/flutter_vk_sdk.dart';

void main() {
  initVkSdk();
  runApp(MaterialApp(home: MyApp()));
}

initVkSdk() {
  return FlutterVkSdk.init(appId: '5555555');
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
        print('LOGIN ERROR: $error}');
        setState(() {
          _value = 'error';
        });
      },
    );
  }

  vkShare() async {
    FlutterVkSdk.share(
      text: 'Some post text.\n#HASHTAG',
      onSuccess: (res) {
        print('SUCCESS: $res}');
        setState(() {
          _value = 'true';
        });
      },
      onError: (error) {
        print('SHARE ERROR: $error}');
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
