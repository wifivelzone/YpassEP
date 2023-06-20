import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:ypass/screen/LoadingScreen.dart';
import 'package:ypass/screen/MainScreen.dart';
import 'package:ypass/screen/SetttingScreen.dart';
import 'package:ypass/screen/TermsOfServiceScreen.dart';
import 'package:ypass/screen/TermsWebView.dart';
import 'package:ypass/screen/UpdateUserDataScreen.dart';

import 'firebase_options.dart';

void main() async {
  //instance 초기화 + methodChannel 통신 안정성 보장, 정적 바인딩
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,); // 파이어 베이스
  KakaoSdk.init(
    nativeAppKey: '83ce8d6e03a7823d0beffa856d0d9e9d',
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,

    initialRoute: '/',
    routes: {
      '/main' : (BuildContext context) => const MainScreen(),
      '/setting' : (BuildContext context) => const SettingScreen(),
      '/updateUser' : (BuildContext context) => const UpdateUserDataScreen(),
      '/termsOfService' : (BuildContext context) => const TermsOfServiceScreen(),
      '/terms' : (BuildContext context) => const TermWebView(),
      '/' : (BuildContext context) => const LoadingScreen(),
    },
  ));
}

