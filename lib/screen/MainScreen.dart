import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:ypass/screen/serve/Bar.dart';
import 'package:ypass/sensor/BleScan.dart';
//import 'package:ypass/sensor/GpsScan.dart';

import '../constant/color.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}
class MyTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  int _eventCount = 0;
  bool isAnd = Platform.isAndroid;

  BleScanService ble = BleScanService();
  //gps는 더미 코드
  //LocationService gps = LocationService();

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    final customData =
    await FlutterForegroundTask.getData<String>(key: 'customData');
    debugPrint('customData: $customData');
    ble.initBle();
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    FlutterForegroundTask.updateService(
      notificationTitle: 'YPass',
      notificationText: 'eventCount: $_eventCount',
    );
    //gps 더미 코드
    //gps.getLocation();
    bool scanR = await ble.scan();
    if (scanR) {
      debugPrint("BLE Scan Success!!");
      bool cloberR = await ble.searchClober();
      if (cloberR) {
        debugPrint("Found Clober");
      }
    } else {
      debugPrint("BLE Scan Fail!!");
    }

    if (ble.findClober()) {
      if (isAnd) {
        debugPrint("IsAndroid from Foreground");
        //일단 둘다 connect
        //ble.writeBle();
        ble.connect();
      } else {
        debugPrint("IsiOS from Foreground");
        ble.connect();
      }
    } else {
      debugPrint("Clober not Found");
    }

    sendPort?.send(_eventCount);

    _eventCount++;
    debugPrint("Is Running?");
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    await FlutterForegroundTask.clearAllData();

  }

  @override
  void onButtonPressed(String id) {
    debugPrint('onButtonPressed >> $id');
  }

  @override
  void onNotificationPressed() {
    if (Platform.isAndroid) {
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

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription: 'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        enableVibration: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<bool> _startForegroundTask() async {
    if (!await FlutterForegroundTask.canDrawOverlays) {
      final isGranted =
      await FlutterForegroundTask.openSystemAlertWindowSettings();
      if (!isGranted) {
        debugPrint('SYSTEM_ALERT_WINDOW permission denied!');
        return false;
      }
    }

    await FlutterForegroundTask.saveData(key: 'customData', value: 'hello');

    final customData =
    await FlutterForegroundTask.getData<String>(key: 'customData');
    debugPrint('customData: $customData');

    final ReceivePort? receivePort = FlutterForegroundTask.receivePort;
    final bool isRegistered = _registerReceivePort(receivePort);
    if (!isRegistered) {
      debugPrint('Failed to register receivePort!');
      return false;
    }

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

  Future<bool> _stopForegroundTask() {
    return FlutterForegroundTask.stopService();
  }

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

  void _closeReceivePort() {
    _receivePort?.close();
    _receivePort = null;
  }

  T? _ambiguate<T>(T? value) => value;

  @override
  void initState() {
    super.initState();
    _initForegroundTask();
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
                    foreIsRun = true;
                  } else {
                    _startForegroundTask();
                    foreIsRun = false;
                  }
                  debugPrint('222');
                },
                child: Image.asset('asset/img/off_ios.png'),
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
          decoration: const BoxDecoration( // 배경 이미지 (십자가) 설정
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

    return Column(
        children: [
          Expanded(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(  // 집으로 호출 버튼
                    child: Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
                      child: TextButton(
                        onPressed: clickedEvCallBtn,
                        child: Image.asset('asset/img/ev.png'),
                      ),
                    ),
                  ),
                  Expanded(  //  사용자 정보 수정 버튼
                    child: Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
                      child: TextButton(
                        onPressed: _clickedUpdateUserDataBtn,
                        child: Image.asset('asset/img/user.png'),
                      ),
                    ),
                  ),
                ]
            ),
          ),
          Expanded(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded( // 셋팅 버튼
                    child: Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
                      child: TextButton(
                        onPressed: clickedSettingBtn,
                        child: Image.asset('asset/img/setting.png'),
                      ),
                    ),
                  ),
                  Expanded( // 집으로 호출 버튼
                    child: Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
                      child: TextButton(
                          onPressed: clickedQuestionBtn,
                          child: Image.asset('asset/img/question.png'),
                      ),
                    ),
                  ),
                ]
            ),
          ),
        ]
    );
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
    return const Padding(
      padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
      child: Text("v.10\n22"),
    );
  }
}

