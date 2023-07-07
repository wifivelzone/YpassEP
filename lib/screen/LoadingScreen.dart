import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ypass/constant/APPInfo.dart';
import 'package:ypass/constant/CustomColor.dart';
import 'package:ypass/realm/UserDBUtil.dart';
import 'package:ypass/realm/db/UserData.dart';
import 'package:ypass/screen/serve/Bar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ypass/screen/serve/Toast.dart';

import 'package:device_info_plus/device_info_plus.dart';

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
    bool rejectPermission = false;
    int andVersion = 0;

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidDeviceInfo =
          await DeviceInfoPlugin().androidInfo;
      andVersion = androidDeviceInfo.version.sdkInt;
    }

    // 위치 정보
    await Permission.location.request().isDenied ? rejectPermission = true : "";
    debugPrint('location$rejectPermission');
    await Permission.locationAlways.request().isDenied
        ? rejectPermission = true
        : "";
    debugPrint('locationAlways$rejectPermission');

    // 블루투스
    if (andVersion < 31) {
      await Permission.bluetooth.request().isDenied
          ? rejectPermission = true
          : "";
      debugPrint('bluetooth$rejectPermission');
    } else if (andVersion >= 33) {
      await Permission.notification.request().isDenied
          ? rejectPermission = true
          : "";
    }
    await Permission.bluetoothConnect.request().isDenied
        ? rejectPermission = true
        : "";
    debugPrint('bluetoothConnect$rejectPermission');
    await Permission.bluetoothScan.request().isDenied
        ? rejectPermission = true
        : "";
    debugPrint('bluetoothScan$rejectPermission');

    await Permission.ignoreBatteryOptimizations.request();
    await Permission.ignoreBatteryOptimizations.isDenied
        ? rejectPermission = true
        : "";
    debugPrint('ignoreBatteryOptimizations$rejectPermission');

    await Permission.systemAlertWindow.request().isDenied
        ? rejectPermission = true
        : ""; // 다른 앱 위에 표시
    debugPrint('systemAlertWindow$rejectPermission');

    // 권한 설정 여부 확인
    if (rejectPermission) {
      CustomToast().showToast("모든 권한을 (항상)허용 하셔야 됩니다.");
      Future.delayed(const Duration(seconds: 2), () {
        SystemNavigator.pop();
      });
    } else {
      // 앱 버전 저장
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      APP_VERSION = packageInfo.version;

      goToMainPage(); // 페이지 이동
    }
  }

  // 페이지 이동
  void goToMainPage() {
    debugPrint('로딩페이지');
    // 페이지 이동
    // 이용 약관 수락한적 있으면 메인페이지로
    // 이용 약관 수락한적 없으면 이용약관 페이지로

    if (SettingDataUtil().isEmpty()) {
      Navigator.pushReplacementNamed(context, '/termsOfService');
    } else {
      UserDBUtil().getDB();
      if (UserDBUtil().isEmpty()) {
        Navigator.of(context)
          ..pushReplacementNamed('/main')
          ..pushNamed('/updateUser');
      } else {
        Navigator.pushReplacementNamed(context, '/main');
      }
    }
  }
}
