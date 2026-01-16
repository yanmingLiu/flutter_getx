import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:encrypt/encrypt.dart';

class Cipher {
  static Key get _key => Key.fromUtf8('yHVav8exzxj6aRc0');
  static IV get _iv => IV.fromUtf8('KLYbJRvhT8eHhgjs');
  static String get _urlPrefix => 'pxuaape0dpkdvdrb';

  static String encrypt(String content) {
    if (content.isEmpty) return content;
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(content, iv: _iv);
    return hex.encode(encrypted.bytes);
  }

  static String decrypt(String encryptedHex) {
    if (encryptedHex.isEmpty) return encryptedHex;
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    final bytes = Uint8List.fromList(hex.decode(encryptedHex));
    return encrypter.decrypt(Encrypted(bytes), iv: _iv);
  }

  static dynamic encryptParams(dynamic params) {
    if (params == null) return null;
    if (params is String) return encrypt(params);
    if (params is Map || params is List) return encrypt(json.encode(params));
    return params;
  }

  static String encryptUrl({required String originalUrl}) {
    final uri = Uri.parse(originalUrl);
    final pathWithQuery =
        '${uri.path}${uri.query.isNotEmpty ? '?${uri.query}' : ''}';

    final encryptedPath = pathWithQuery.isNotEmpty
        ? encrypt(pathWithQuery)
        : '';

    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.port,
      path: '/$_urlPrefix/$encryptedPath',
    ).toString();
  }
}
