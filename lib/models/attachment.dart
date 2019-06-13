enum AttachmentType { photo, url }

class Attachment {
  final AttachmentType type;
  final String value;

  Attachment(this.type, this.value)
      : assert(type != null),
        assert(value != null);

  @override
  bool operator ==(other) {
    return other is Attachment && type == other.type && value == other.value;
  }

  @override
  int get hashCode => type.hashCode + value.hashCode;
}
