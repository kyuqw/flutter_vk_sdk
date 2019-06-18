import 'package:flutter/material.dart';
import 'package:flutter_vk_sdk/flutter_vk_sdk.dart';
import 'package:flutter_vk_sdk/models/attachment.dart';
import 'package:flutter_vk_sdk/vk_scope.dart';

import 'package:camera_utils/camera_utils.dart';

void main() {
  initVKSdk();
  runApp(MaterialApp(home: MyApp()));
}

initVKSdk() {
  return FlutterVKSdk.init(appId: '7012114');
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
    var isLoggedIn = await FlutterVKSdk.isLoggedIn();
    setState(() {
      _value = isLoggedIn.toString();
    });
  }

  void vkLogin() async {
    FlutterVKSdk.login(
      scope: '${VKScope.wall}, ${VKScope.photos}, ${VKScope.video}',
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
    FlutterVKSdk.shareWithDialog(
      context: context,
      text: 'Some post text.\n#HASHTAG',
      addAttachments: addAttachments,
      onSuccess: handleShareSuccess,
      onError: handleShareError,
    );
  }

  Future<List<Attachment>> addAttachments(AttachmentType type) async {
    String path;
    String thumbnail;
    if (type == AttachmentType.photo) {
      path = await CameraUtils.pickImage;
    } else if (type == AttachmentType.video) {
      path = await CameraUtils.pickVideo;
      if (path != null) thumbnail = await CameraUtils.getThumbnail(path);
    }

    if (path == null) return null;
    return [Attachment(type, path, thumbnail: thumbnail)];
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
      floatingActionButton: FloatingActionButton(onPressed: logout, child: Icon(Icons.close)),
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

  logout() {
    FlutterVKSdk.logout();
  }
}
