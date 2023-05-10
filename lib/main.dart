import 'package:flutter/material.dart';
import 'package:ypass/screen/LoadingScreen.dart';
import 'package:ypass/screen/MainScreen.dart';
import 'package:ypass/screen/SetttingScreen.dart';
import 'package:ypass/screen/UpdateUserDataScreen.dart';

void main() async {
  //instance 초기화 + methodChannel 통신 안정성 보장, 정적 바인딩
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

