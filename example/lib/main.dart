import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_vk_sdk/flutter_vk_sdk.dart';
import 'package:flutter_vk_sdk/models/attachment.dart';
import 'package:flutter_vk_sdk/vk_scope.dart';

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
      scope: '${VkScope.wall}, ${VkScope.photos}',
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
    FlutterVkSdk.shareWithDialog(
      context: context,
      text: 'Some post text.\n#HASHTAG',
      addAttachments: addAttachments,
      onSuccess: handleShareSuccess,
      onError: handleShareError,
    );
  }

  Future<List<String>> addAttachments(AttachmentType type) async {
    var pickingType;
    switch (type) {
      case AttachmentType.photo:
        pickingType = FileType.IMAGE;
        break;
      case AttachmentType.url:
        break;
    }
    if (pickingType == null) return null;
    final paths = await FilePicker.getMultiFilePath(type: pickingType);
    if (paths == null) return null;
    return paths.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }

  handleShareSuccess(res) {
    print('SUCCESS: $res}');
    setState(() {
      _value = 'true';
    });
  }

  handleShareError(error) {
    print('SHARE ERROR: $error}');
    setState(() {
      _value = 'error';
    });
  }
}
