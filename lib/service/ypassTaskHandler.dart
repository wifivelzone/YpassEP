import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:ypass/service/sensor/BleScan.dart';
import 'package:ypass/realm/UserDBUtil.dart';
import '../http/UserDataRequest.dart';

//foreground task 시작
@pragma('vm:entry-point')
void startCallback() {
  //Foreground task는 main app 작동과 분리되므로 여기도 instance 초기화 보장 한번 더
  //안하면 ble 스캔 안됨
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.setTaskHandler(YPassTaskHandler());
}

//foreground 작동
class YPassTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  bool isAnd = Platform.isAndroid;

  //ble 시작
  BleScanService ble = BleScanService();
  UserDBUtil db = UserDBUtil();

  //gps는 더미 코드
  //LocationService gps = LocationService();

  //알림창 기본 설정
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    //foreground task 자체에 저장된 데이터 가져오기 (예시 코드)
    final customData =
    await FlutterForegroundTask.getData<String>(key: 'customData');
    debugPrint('customData: $customData');
    //ble init
    ble.initBle();
    db.getDB();

    //사용기간 체크해서 UserData갱신
    var find = db.getUser();
    DateTime sDate = DateTime.parse(find.sDate);
    DateTime eDate = DateTime.parse(find.eDate);
    debugPrint("sDate : $sDate");
    debugPrint("eDate : $eDate");

    DateTime now = DateTime.now();
    int vaildTime = eDate.millisecondsSinceEpoch - sDate.millisecondsSinceEpoch;
    int useTime = now.millisecondsSinceEpoch - sDate.millisecondsSinceEpoch;
    debugPrint("sDate ~ eDate : $vaildTime");
    debugPrint("sDate ~ Now : $useTime");
    if (vaildTime < useTime*3) {
      debugPrint("Update UserData");
      debugPrint("phoneNumber : ${find.phoneNumber}");
      if (find.phoneNumber != "1") {
        debugPrint("갱신 시작");
        await UserDataRequest().setUserData(find.phoneNumber);
      } else {
        debugPrint("관리자 PASS");
      }
    } else {
      debugPrint("Not Update Time");
    }
    //표시되는 push 창 업데이트
    FlutterForegroundTask.updateService(
      notificationTitle: 'YPass',
    );
  }

  //push가 올 때마다 실행
  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    //gps 더미 코드
    //gps.getLocation();

    if (ble.scanRestart && !ble.connecting) {
      await ble.scan();
    }
    //스캔 결과 따라 Clober search
    if (ble.scanDone && !ble.connecting) {
      //debugPrint("Connected Device Check : ${await ble.flutterBlue.connectedDevices}");
      debugPrint("List Check : ${ble.cloberList}");
      debugPrint("BLE Scan Success!!");
      await ble.searchClober();
    }

    //clober search 결과 따라
    if (ble.searchDone && !ble.connecting) {
      if (ble.findClober()) {
        if (isAnd) {
          debugPrint("IsAndroid from Foreground");
          //일단 둘다 connect
          //ble.writeBle();
          try {
            await ble.connect().then((value) {
              ble.disconnect();
            });
          } catch (e) {
            ble.disconnect();
            debugPrint("Connect Error!!!");
            debugPrint("Error log : ${e.toString()}");
          }
        } else {
          debugPrint("IsiOS from Foreground");
          try {
            await ble.connect().then((value) {
              ble.disconnect();
            });
          } catch (e) {
            ble.disconnect();
            debugPrint("Connect Error!!!");
          }
        }
      } else {
        debugPrint("Clober not Found");
      }
    }
  }

  //foreground task가 끝날 때
  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    //진행 중이던 스캔 정지 (안하면 listener가 더미로 남음)
    ble.stopScan();
    //ble 연결 도중이면 끊기 (안하면 연결 상태가 더미로 남음)
    ble.disposeBle();
    ble.disconnect();
    await FlutterForegroundTask.clearAllData();
  }

  //push안에 버튼을 눌렀을 때 (여기선 버튼 구현 안함)
  @override
  void onButtonPressed(String id) {
    debugPrint('onButtonPressed >> $id');
  }

  //push를 직접 눌렀을 때
  @override
  void onNotificationPressed() {
    if (Platform.isAndroid) {
      //앱이 워하는 route로 실행됨 (materialApp에서 route설정 해야함)
      FlutterForegroundTask.launchApp("/");
    }
    _sendPort?.send('onNotificationPressed');
  }
}
