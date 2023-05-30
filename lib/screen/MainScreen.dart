import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ypass/realm/SettingDBUtil.dart';
import 'package:ypass/screen/serve/Bar.dart';
import 'package:ypass/sensor/BleScan.dart';
import 'package:ypass/realm/UserDBUtil.dart';
import 'package:ypass/screen/serve/Toast.dart';

//import 'package:ypass/sensor/GpsScan.dart';

import '../constant/CustomColor.dart';
import '../constant/YPassURL.dart';
import '../http/HttpPostData.dart' as http;
import '../http/UserDataRequest.dart';

//foreground task 시작
@pragma('vm:entry-point')
void startCallback() {
  //Foreground task는 main app 작동과 분리되므로 여기도 instance 초기화 보장 한번 더
  //안하면 ble 스캔 안됨
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

//foreground 작동
class MyTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  int _eventCount = 0;
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
      await UserDataRequest().setUserData(find.phoneNumber);
    } else {
      debugPrint("Not Update Time");
    }
  }

  //push가 올 때마다 실행
  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    //표시되는 push 창 업데이트
    FlutterForegroundTask.updateService(
      notificationTitle: 'YPass',
      notificationText: 'eventCount: $_eventCount',
    );
    //gps 더미 코드
    //gps.getLocation();

    if (ble.scanRestart && !ble.connecting) {
      await ble.scan();
    }
    //스캔 결과 따라 Clober search
    if (ble.scanDone && !ble.connecting) {
      debugPrint("Connected Device Check : ${await ble.flutterBlue.connectedDevices}");
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

    _eventCount++;
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

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MAIN_BACKGROUND_COLOR,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Bar(barSize: 5.0),
            Top(),
            Bar(barSize: 5.0),
            _Middle(),
            Bar(barSize: 5.0),
            Bottom(),
          ],
        ),
      ),
    );
  }
}

/** ---------------------------------------------------- */
/** --------------------   상단 부분  --------------------- */

/// -------------------------------------------------------

class Top extends StatefulWidget {
  const Top({Key? key}) : super(key: key);

  @override
  State<Top> createState() => _TopState();
}

class _TopState extends State<Top> {
  ReceivePort? _receivePort;
  bool isAnd = Platform.isAndroid;
  bool foreIsRun = SettingDataUtil().isEmpty() ? false : SettingDataUtil().getStateOnOff(); // on off 버튼
  bool inActive = false;
  UserDBUtil db = UserDBUtil();

  //foureground task 기본 설정
  void _initForegroundTask() {
    FlutterForegroundTask.init(
      //안드로이드 설정
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        //push 아이콘은 앱 아이콘 따라감(기본설정)
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        enableVibration: true,
      ), //iOS 설정
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ), //push 관련 설정
      foregroundTaskOptions: const ForegroundTaskOptions(
        //interval (millisecond)마다 push 가능 (이걸 통해 onEvent로 주기적으로 BLE 스캔 작동시킴)
        interval: 200,  //12000
        //1번만 push설정
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  //foreground task 시작 함수
  Future<bool> _startForegroundTask() async {
    //permission check
    if (!await FlutterForegroundTask.canDrawOverlays) {
      final isGranted =
          await FlutterForegroundTask.openSystemAlertWindowSettings();
      if (!isGranted) {
        debugPrint('SYSTEM_ALERT_WINDOW permission denied!');
        return false;
      }
    }

    //foreground task 자체로 data 저장 기능 지원 (영구 저장은 아님)
    await FlutterForegroundTask.saveData(key: 'customData', value: 'hello');
    await FlutterForegroundTask.saveData(key: 'isRun', value: true);

    final customData =
        await FlutterForegroundTask.getData<String>(key: 'customData');
    debugPrint('customData: $customData');

    //foreground task랑 통신 가능한 port (수신)
    final ReceivePort? receivePort = FlutterForegroundTask.receivePort;
    final bool isRegistered = _registerReceivePort(receivePort);
    if (!isRegistered) {
      debugPrint('Failed to register receivePort!');
      return false;
    }

    //foreground task가 이미 작동 중인지 check
    if (await FlutterForegroundTask.isRunningService) {
      debugPrint("Foreground Already Running");
      return FlutterForegroundTask.startService(
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    } else {
      debugPrint("Foreground Start Running");
      return FlutterForegroundTask.startService(
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    }
  }

  //foreground task 정지
  Future<bool> _stopForegroundTask() {
    FlutterForegroundTask.saveData(key: 'isRun', value: false);
    return FlutterForegroundTask.stopService();
  }

  //통신 port 수신 데이터 처리
  bool _registerReceivePort(ReceivePort? newReceivePort) {
    if (newReceivePort == null) {
      return false;
    }

    _closeReceivePort();

    _receivePort = newReceivePort;
    _receivePort?.listen((message) {
      if (message is int) {
        debugPrint('eventCount: $message');
      } else if (message is String) {
        if (message == 'onNotificationPressed') {
          Navigator.of(context).pushNamed('/');
        }
      } else if (message is DateTime) {
        debugPrint('timestamp: ${message.toString()}');
      }
    });

    return _receivePort != null;
  }

  //통신 port 종료
  void _closeReceivePort() {
    _receivePort?.close();
    _receivePort = null;
  }

  //정확한 작동 원리는 파악 안됨
  T? _ambiguate<T>(T? value) => value;

  @override
  void initState() {
    super.initState();
    db.getDB();
    //foreground task 기본 설정
    _initForegroundTask();
    //port 설정 + foreground task 재시작 시 기존 port 가져오기
    _ambiguate(WidgetsBinding.instance)?.addPostFrameCallback((_) async {
      if (await FlutterForegroundTask.isRunningService) {
        final newReceivePort = FlutterForegroundTask.receivePort;
        _registerReceivePort(newReceivePort);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              width: MediaQuery.of(context).size.width.toDouble() * 0.4,
              child: Image.asset('asset/img/ypass2.png'),
            ),
          ),
          const Flexible(
            child: Text('입주민님 환영합니다.'),
          ),
          Expanded(
            child: SizedBox(
              width: MediaQuery.of(context).size.width.toDouble() * 0.3,
              child: TextButton(
                onPressed: () async {
                  if (db.isEmpty()) {
                    CustomToast().showToast("사용자 정보 추가가 필요합니다.");
                    debugPrint("DB 없다");
                  } else {
                    if (!inActive) {
                      inActive = true;
                      if (foreIsRun) {
                        foreIsRun = false;
                        _stopForegroundTask();
                      } else {
                        foreIsRun = true;
                        _startForegroundTask();
                      }
                      SettingDataUtil().setStateOnOff(foreIsRun);
                      setState(() {});
                      await Future.delayed(const Duration(milliseconds: 1000));
                      inActive = false;
                    } else {
                      CustomToast().showToast("잠시만 기다려 주십시오.");
                      debugPrint("On/Off 시간초 제한 중");
                    }
                  }
                  debugPrint('222');
                },
                child: foreIsRun
                    ? Image.asset('asset/img/on_ios.png')
                    : Image.asset('asset/img/off_ios.png'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/** ---------------------------------------------------- */
/** --------------------   중간 부분  --------------------- */
/// -------------------------------------------------------

class _Middle extends StatelessWidget {
  const _Middle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 3, 25, 3),
        child: Container(
          decoration: const BoxDecoration(
            // 배경 이미지 (십자가) 설정
            image: DecorationImage(
                image: AssetImage('asset/img/icon_bg.png'), fit: BoxFit.cover),
          ),
          child: _MiddleButtonImg(),
        ),
      ),
    );
  }
}

class _MiddleButtonImg extends StatelessWidget {
  BuildContext? context;
  UserDBUtil userDBUtil = UserDBUtil();

  _MiddleButtonImg({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    this.context = context;

    return Column(children: [
      Expanded(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(
            // 집으로 호출 버튼
            child: Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
              child: TextButton(
                onPressed: clickedEvCallBtn,
                child: Image.asset('asset/img/ev.png'),
              ),
            ),
          ),
          Expanded(
            //  사용자 정보 수정 버튼
            child: Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
              child: TextButton(
                onPressed: _clickedUpdateUserDataBtn,
                child: Image.asset('asset/img/user.png'),
              ),
            ),
          ),
        ]),
      ),
      Expanded(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(
            // 셋팅 버튼
            child: Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
              child: TextButton(
                onPressed: clickedSettingBtn,
                child: Image.asset('asset/img/setting.png'),
              ),
            ),
          ),
          Expanded(
            // 문의 하기 버튼
            child: Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
              child: TextButton(
                onPressed: clickedQuestionBtn,
                child: Image.asset('asset/img/question.png'),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  // 엘레베이터 집으로 호출 버튼 클릭시
  clickedEvCallBtn() async {
    userDBUtil.getDB();
    if (userDBUtil.isEmpty()) {
      CustomToast().showToast("사용자 정보 추가가 필요합니다.");
    } else {
      var user = userDBUtil.getUser();
      List addr = userDBUtil.getDong();
      String result = "";
      result = await http.homeEvCall(user.phoneNumber, addr[0], addr[1]);
      debugPrint("통신 결과 : $result");
      debugPrint("1");
      /*UserDataRequest a = UserDataRequest();
    a.getUserData('01027283301');*/
    }
    // await UserDataRequest().setUserData('01027283301');
  }

  // 사용자 정보 수정 버튼 클릭시
  _clickedUpdateUserDataBtn() {
    if (context != null) {
      Navigator.of(context!).pushNamed('/updateUser');
    }
  }

  // 설정 버튼 클릭시
  void clickedSettingBtn() {
    if (userDBUtil.isEmpty()) {
      CustomToast().showToast("사용자 정보 추가가 필요합니다.");
    } else {
      if (context != null) {
        Navigator.of(context!).pushNamed('/setting');
      }
    }
  }

  // 문의 버튼 클릭시
  Future<void> clickedQuestionBtn() async {
    if (await isKakaoTalkInstalled()) {
      Uri url = await TalkApi.instance.channelChatUrl('_cZBEK');
      try {
        await launchBrowserTab(url);
      } catch (error) {
        debugPrint('카카오톡 채널 채팅 실패 $error');
      }
    } else {
      CustomToast().showToast('카카오톡을 설치해 주세요');
    }
    // debugPrint("4");
  }

}

/** ---------------------------------------------------- */
/** --------------------   하단 부분  --------------------- */
/// -------------------------------------------------------

class Bottom extends StatelessWidget {
  const Bottom({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(
        height: 5,
      ),
      const Text('1.0.0v'),
      const SizedBox(
        height: 5,
      ),
      const Text('© 2019 WiFive Inc. All rights reserved'),
      const SizedBox(
        height: 5,
      ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        TextButton(
            onPressed: () => {

              _launchUrl(Uri.parse(PRIVACY_TERMS_OF_SERVICE))
                  //TODO: 약관 화면 표시
            },
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size.zero),
            child: const Text('개인정보 제 3자 제공 동의 약관',
                style: TextStyle(color: Colors.black))),
        const SizedBox(
          width: 10,
        ),
        TextButton(
          onPressed: () => {
            //TODO: 약관 화면 표시
            _launchUrl(Uri.parse(YPASS_TERMS_OF_SERVICE))
          },
          style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero),
          child: const Text('와이패스 이용약관', style: TextStyle(color: Colors.black)),
        )
      ]),
      const SizedBox(
        height: 15,
      )
    ]);
  }

  Future<void> _launchUrl(url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}
