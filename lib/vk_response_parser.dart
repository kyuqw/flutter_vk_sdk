import 'dart:convert';

abstract class VKResponseParser<T> {
  T parse(String response);
}

class VKApiResponseParser implements VKResponseParser {
  final _responseKey = 'response';

  @override
  parse(String response) {
    final res = json.decode(response);
    if (res == null || !(res is Map) || !res.containsKey(_responseKey)) return res;
    return res[_responseKey];
  }
}
