import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_vk_sdk/utils/share_utils.dart';

import '../models/attachment.dart';
import 'VkThemeData.dart';

enum UITheme { vk, app }

class VkSharePage extends StatefulWidget {
  final Function onSuccess;
  final Function onError;
  final String text;
  final List<Attachment> attachments;
  final Future<List> Function(AttachmentType) addAttachments;
  final UITheme theme;

  const VkSharePage({
    Key key,
    this.onSuccess,
    this.onError,
    this.text,
    this.attachments,
    this.addAttachments,
    this.theme = UITheme.vk,
  })  : assert(onSuccess != null),
        assert(onError != null),
        assert(theme != null),
        super(key: key);

  @override
  VkSharePageState createState() => VkSharePageState();

  static Future show({
    @required BuildContext context,
    @required Function onSuccess,
    @required Function onError,
    String text,
    List attachments,
    Future<List> Function(AttachmentType) addAttachments,
    theme = UITheme.vk,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => VkSharePage(
              onSuccess: onSuccess,
              onError: onError,
              text: text,
              attachments: attachments,
              addAttachments: addAttachments,
              theme: theme,
            ),
      ),
    );
  }
}

class VkSharePageState extends State<VkSharePage> {
  bool isLoading = false;
  TextEditingController textCtrl;
  List<Attachment> attachments;

  @override
  void initState() {
    super.initState();
    textCtrl = TextEditingController(text: widget.text);
    attachments = widget.attachments ?? [];
  }

  @override
  void dispose() {
    textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = Scaffold(
      appBar: buildAppBar(context),
      body: buildBody(context),
    );

    if (widget.theme == UITheme.vk) return buildVkTheme(context, child);
    return child;
  }

  Widget buildVkTheme(BuildContext context, Widget child) {
    final themeData = VkTheme.getTheme(context);
    return Theme(data: themeData, child: child);
  }

  Widget buildAppBar(BuildContext context) {
//    final theme = Theme.of(context).iconTheme;
    final iconColor = null;
    return AppBar(
      leading: CustomIconButton(
        child: Icon(Icons.arrow_back, color: iconColor),
        onTap: handleBackButtonTap,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
      actions: <Widget>[
        AspectRatio(
          aspectRatio: 1.0,
          child: CustomIconButton(child: Icon(Icons.check, color: iconColor), onTap: handleDoneButtonTap),
        ),
      ],
    );
  }

  Widget buildBody(BuildContext context) {
    final List<Widget> children = [
      Layout(
        child: buildContent(context),
        bottom: buildBottomBar(context),
      )
    ];
    if (isLoading) children.add(buildLoaderIndicator(context));
    return Stack(children: children);
  }

  Widget buildLoaderIndicator(BuildContext context) {
    return AbsorbPointer(child: Center(child: CircularProgressIndicator()));
  }

  Widget buildContent(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 12.0),
      children: <Widget>[
        buildTextInput(context),
        buildAttachments(context),
      ],
    );
  }

  Widget buildTextInput(BuildContext context) {
    return TextField(
      minLines: 1,
      maxLines: 20,
      controller: textCtrl,
      decoration: InputDecoration(
        border: InputBorder.none,
      ),
    );
  }

  Widget buildAttachments(BuildContext context) {
    return AttachmentsWidget(
      onRemove: handleOnRemoveAttachment,
      attachments: attachments,
    );
  }

  Widget buildBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> children = [];
    final image = buildAddImageButton(context);
    if (image != null) children.add(image);
    if (children.length == 0) return null;
    return BottomAppBar(
      child: Container(
        height: kBottomNavigationBarHeight,
        color: theme.bottomAppBarColor,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }

  Widget buildAddImageButton(BuildContext context) {
    if (widget.addAttachments == null) return null;
    return AspectRatio(aspectRatio: 1, child: CustomIconButton(child: Icon(Icons.image), onTap: handleAddImageTap));
  }

  handleBackButtonTap() {
    navigateBack();
  }

  handleDoneButtonTap() {
    share();
  }

  navigateBack() {
    Navigator.pop(context);
  }

  handleAddImageTap() {
    addAttachments(AttachmentType.photo);
  }

  addAttachments(AttachmentType type) async {
    if (widget.addAttachments == null || isLoading) return;
    final items = await widget.addAttachments(type);
    if (items == null) return;
    items.forEach((f) {
      final item = Attachment(type, f);
      if (!attachments.contains(item)) attachments.add(item);
    });
    setState(() {});
  }

  handleOnRemoveAttachment(Attachment attachment) {
    if (attachment == null) return;
    attachments.remove(attachment);
    setState(() {});
  }

  setLoading(bool value) {
    if (isLoading == value) return;
    setState(() {
      isLoading = value;
    });
  }

  share() {
    if (isLoading) return;
    setLoading(true);
    final text = textCtrl.text;
    Share().execute(
      onSuccess: handleShareSuccess,
      onError: handleShareError,
      message: text,
      attachments: attachments,
    );
  }

  handleShareSuccess(postId) {
    setLoading(false);
    widget.onSuccess(postId);
    navigateBack();
  }

  handleShareError(error) {
    setLoading(false);
    widget.onError(error);
  }
}

class CustomIconButton extends StatelessWidget {
  final Widget child;
  final String tooltip;
  final Function() onTap;
  final Color color;

  const CustomIconButton({Key key, this.child, @required this.onTap, this.tooltip, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var content = child;
    if (tooltip?.isNotEmpty == true) content = Tooltip(message: tooltip, child: content);
    return Container(
      padding: EdgeInsets.all(4.0),
      child: Material(
        type: color == null ? MaterialType.transparency : MaterialType.canvas,
        shape: CircleBorder(),
        color: color,
        clipBehavior: Clip.hardEdge,
        child: InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class Layout extends StatelessWidget {
  final Widget top;
  final Widget child;
  final Widget bottom;

  const Layout({Key key, this.top, this.bottom, this.child})
      : assert(child != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];
    if (top != null) children.add(top);
    children.add(Expanded(child: child));
    if (bottom != null) children.add(bottom);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class AttachmentsWidget extends StatelessWidget {
  final List<Attachment> attachments;
  final Function(Attachment) onRemove;

  const AttachmentsWidget({Key key, this.attachments, this.onRemove}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (attachments == null) return Container();

    final List<Widget> children = [];
    final List<Widget> urls = [];
    attachments.forEach((a) {
      final child = AttachmentPreview(item: a, onRemove: onRemove, perRow: min(attachments.length, 4));
      if (a.type == AttachmentType.url)
        urls.add(child);
      else
        children.add(child);
    });
    children.addAll(urls);
    return Wrap(
      alignment: WrapAlignment.spaceAround,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

class AttachmentPreview extends StatelessWidget {
  final Attachment item;
  final int perRow;
  final Function(Attachment) onRemove;

  const AttachmentPreview({Key key, this.item, this.perRow = 1, this.onRemove}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (item.type) {
      case AttachmentType.url:
        child = buildUrl(context);
        break;
      case AttachmentType.photo:
        child = buildPhoto(context);
        break;
      default:
        break;
    }
    return Card(
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: <Widget>[
          child,
          Positioned(right: 0.0, child: buildRemoveButton(context)),
        ],
      ),
    );
  }

  Widget buildRemoveButton(BuildContext context) {
    if (onRemove == null) return Container();
    final theme = Theme.of(context);
    final size = 18.0;
    return CustomIconButton(
      onTap: handleOnRemoveTap,
      color: theme.canvasColor,
      child: Icon(Icons.close, size: size),
    );
  }

  Widget buildUrl(BuildContext context) {
    final padding = 4.0;
    return Container(
      padding: EdgeInsets.only(left: padding, top: padding, right: 20.0, bottom: padding),
      child: Text(item.value),
    );
  }

  Widget buildPhoto(BuildContext context) {
    final size = getMediaWidth(context, perRow);
    final minSize = 80.0;
    return Container(
      constraints: BoxConstraints(minWidth: minSize, maxWidth: size, minHeight: minSize, maxHeight: size),
      child: Image.asset(item.value, fit: BoxFit.cover),
    );
  }

  double getMediaWidth(BuildContext context, int countPerRow) {
    assert(countPerRow > 0);

    final theme = Theme.of(context).cardTheme;
    final margin = theme.margin?.horizontal ?? 0.0;
    var width = MediaQuery.of(context).size.width;
    width = (width - margin * countPerRow) / countPerRow;
//    width = min(width, 180.0);
    return width;
  }

  handleOnRemoveTap() {
    if (onRemove == null) return;
    onRemove(item);
  }
}
