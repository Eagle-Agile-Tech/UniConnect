import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/uni_connect.dart';

void main() {
  WidgetsBinding widgetBinding = WidgetsFlutterBinding.ensureInitialized();
  //FlutterNativeSplash.preserve(widgetsBinding: widgetBinding);
  runApp(const ProviderScope(child: UniConnect()));
}