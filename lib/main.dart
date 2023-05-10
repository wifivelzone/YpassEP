import 'package:flutter/material.dart';
import 'package:ypass/screen/LoadingScreen.dart';

import 'package:permission_handler/permission_handler.dart';


void main() {
  
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LoadingScreen(),
  ));
}


