import 'package:flutter/material.dart';
import 'package:ypass/screen/LoadingScreen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,

    home: LoadingScreen(),
  ));
}

