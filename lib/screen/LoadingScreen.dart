import 'package:flutter/material.dart';
import 'package:ypass/constant/CustomColor.dart';
import 'package:ypass/screen/serve/Bar.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:io';

import '../realm/SettingDBUtil.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {

  bool isAnd = Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    checkPermission(); // 권한 확인
  }

  @override
  Widget build(BuildContext context) {
    Permission.location.isGranted;


    return Scaffold(
      backgroundColor: MAIN_BACKGROUND_COLOR,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Bar(barSize: 10.0),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.2,
              child: Image.asset('asset/img/wifive.png'),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.2,
              child: Image.asset('asset/img/y5logo.png'),
            ),

            const Bar(barSize: 10.0),
          ],
        ),
      ),
    );
  }

  // 권한 설정
  Future<void> checkPermission() async {
    // 위치 정보
    await Permission.location.request();
    await Permission.locationAlways.request();

    // 블루투스
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();

    await Permission.ignoreBatteryOptimizations.request(); // 배터리 사용량 최적화 중지
    await Permission.systemAlertWindow.request(); // 다른 앱 위에 표시

    // 페이지 이동
    goToMainPage();
  }

  // 페이지 이동
  void goToMainPage() {
    debugPrint('로딩페이지');
    // 페이지 이동
    // 이용 약관 수락한적 있으면 메인페이지로
    // 이용 약관 수락한적 없으면 이용약관 페이지로
    String nextRoute;
    if (SettingDataUtil().isEmpty()) {
      nextRoute = '/termsOfService';
    } else {
      nextRoute = '/main';
    }
    Navigator.pushReplacementNamed(
      context, nextRoute
    );
  }
}
