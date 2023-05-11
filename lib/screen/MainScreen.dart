import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:ypass/screen/serve/Bar.dart';
import 'package:ypass/sensor/BleScan.dart';

//import 'package:ypass/sensor/GpsScan.dart';

import '../constant/color.dart';

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
    bool scanR = await ble.scan();
    //ble 스캔 끝나고 작동하게 delay
    await Future.delayed(const Duration(milliseconds: 4500));
    //스캔 결과 따라 Clober search
    if (scanR) {
      debugPrint("BLE Scan Success!!");
      bool cloberR = await ble.searchClober();
      if (cloberR) {
        debugPrint("Found Clober");
      }
    } else {
      debugPrint("BLE Scan Fail!!");
    }

    //clober search 결과 따라
    if (ble.findClober()) {
      if (isAnd) {
        debugPrint("IsAndroid from Foreground");
        //일단 둘다 connect
        //ble.writeBle();
        ble.connect().then((value) {
          ble.disconnect();
        });
      } else {
        debugPrint("IsiOS from Foreground");
        ble.connect().then((value) {
          ble.disconnect();
        });
      }
    } else {
      debugPrint("Clober not Found");
    }

    sendPort?.send(_eventCount);

    _eventCount++;
    debugPrint("Is Running?");
  }

  //foreground task가 끝날 때
  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    //진행 중이던 스캔 정지 (안하면 listener가 더미로 남음)
    ble.stopScan();
    //ble 연결 도중이면 끊기 (안하면 연결 상태가 더미로 남음)
    ble.disposeBle();
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
      FlutterForegroundTask.launchApp("/loading");
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
    return Scaffold(
      backgroundColor: MAIN_BACKGROUND_COLOR,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
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
  bool foreIsRun = false;

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
        showNotification: true,
        playSound: false,
      ), //push 관련 설정
      foregroundTaskOptions: const ForegroundTaskOptions(
        //interval (millisecond)마다 push 가능 (이걸 통해 onEvent로 주기적으로 BLE 스캔 작동시킴)
        interval: 10000,
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
                onPressed: () {
                  if (foreIsRun) {
                    _stopForegroundTask();
                    foreIsRun = false;
                  } else {
                    _startForegroundTask();
                    foreIsRun = true;
                  }
                  debugPrint('222');
                  setState(() {});
                },
                child: foreIsRun
                    ? Image.asset('asset/img/off_ios.png')
                    : Image.asset('asset/img/on_ios.png'),
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
            // 집으로 호출 버튼
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
  clickedEvCallBtn() {
    debugPrint("1");
  }

  // 사용자 정보 수정 버튼 클릭시
  _clickedUpdateUserDataBtn() {
    if (context != null) {
      Navigator.of(context!).pushNamed('/updateUser');
      /*Navigator.push(
        context!,
          MaterialPageRoute(
            builder: (BuildContext contex) => const UpdateUserDataScreen(),
        ),
      );*/
    }
  }

  // 설정 버튼 클릭시
  void clickedSettingBtn() {
    if (context != null) {
      Navigator.of(context!).pushNamed('/setting');
      /*Navigator.push(
        context!,
        MaterialPageRoute(
          builder: (BuildContext contex) => const SettingScreen(),
        ),
      );*/
    }
  }

  // 문의 버튼 클릭시
  clickedQuestionBtn() {
    debugPrint("4");
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
      Text('1.0.0v'),
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
}
