import 'package:flutter/material.dart';
import 'package:ypass/screen/LoadingScreen.dart';
import 'package:ypass/screen/MainScreen.dart';
import 'package:ypass/screen/SetttingScreen.dart';
import 'package:ypass/screen/UpdateUserDataScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,

    initialRoute: '/loading',
    routes: {
      '/' : (BuildContext context) => const MainScreen(),
      '/setting' : (BuildContext context) => const SettingScreen(),
      '/updateUser' : (BuildContext context) => const UpdateUserDataScreen(),
      '/loading' : (BuildContext context) => const LoadingScreen(),
    },
  ));
}

