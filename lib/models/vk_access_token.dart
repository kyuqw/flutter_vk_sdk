class VKAccessToken {
  final int userId;
  final String token;
  final String secret;
  final String email;
  final String phone;
  final String phoneAccessKey;

  VKAccessToken(this.userId, this.token, this.secret, this.email, this.phone, this.phoneAccessKey);

  VKAccessToken.fromJson(Map<String, dynamic> json)
      : assert(json != null),
        userId = json['userId'],
        token = json['token'],
        secret = json['secret'],
        email = json['email'],
        phone = json['phone'],
        phoneAccessKey = json['phoneAccessKey'];
}
