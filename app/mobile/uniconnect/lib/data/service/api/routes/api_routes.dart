import 'dart:io';
import 'package:flutter/foundation.dart';

String get baseUrl {
  // Use your Ubuntu machine's local IP address for physical devices
  const String machineIp = '10.141.130.200';
  
  if (kIsWeb) return 'http://localhost:3000/api';
  if (Platform.isAndroid) {
    // Check if you are using an emulator or physical device. 
    // For simplicity, we use the machine IP which works for both if on the same network.
    return 'http://$machineIp:3000/api';
  }
  return 'http://$machineIp:3000/api';
}


abstract final class ApiRoutes{

  static const posts = 'posts';
  static const createPost = 'createPost';
}