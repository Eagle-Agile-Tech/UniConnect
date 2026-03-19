import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_dio/fresh_dio.dart';

class SecureTokenStorage extends TokenStorage<OAuth2Token>{
  final _storage = FlutterSecureStorage();
  final String _key = 'auth_tokens';

  @override
  Future<void> delete() async => _storage.delete(key: _key);

  @override
  Future<OAuth2Token?> read() async{
    final tokenJson = await _storage.read(key: _key);
    if(tokenJson == null){
      return null;
    }
    final token = jsonDecode(tokenJson);
    return OAuth2Token(
      accessToken: token['accessToken'],
      refreshToken: token['refreshToken']
    );
  }

  @override
  Future<void> write(OAuth2Token token) async {
    final tokenJson = jsonEncode({
      'accessToken': token.accessToken,
      'refreshToken': token.refreshToken
    });
    await _storage.write(key: _key, value: tokenJson);
  }
  
}