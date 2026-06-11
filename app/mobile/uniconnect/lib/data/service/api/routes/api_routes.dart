import 'dart:io';
import 'package:flutter/foundation.dart';

String get baseUrl {
  // ip -4 addr show
  const String machineIp = '10.136.242.191';
  
  if (kIsWeb) return 'http://localhost:3000/api';
  if (Platform.isAndroid) {
    return 'http://$machineIp:3000/api';
  }
  return 'http://$machineIp:3000/api';
}


abstract final class ApiRoutes{

  static const posts = 'posts';
  static const createPost = 'createPost';
}