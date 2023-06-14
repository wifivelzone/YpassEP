import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ypass/constant/APPInfo.dart';

import 'package:ypass/realm/SettingDBUtil.dart';
import 'package:ypass/screen/serve/Bar.dart';
import 'package:ypass/realm/UserDBUtil.dart';
import 'package:ypass/screen/serve/Toast.dart';
import 'package:ypass/service/ypassTaskSetting.dart';
import '../constant/CustomColor.dart';
import '../constant/YPassURL.dart';
import '../http/HttpPostData.dart' as http;


import 'package:upgrader/upgrader.dart';

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
        child: UpgradeAlert(
          child: const Column(
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
  bool isAnd = Platform.isAndroid;
  bool foreIsRun = SettingDataUtil().isEmpty() ? false : SettingDataUtil().getStateOnOff(); // on off 버튼
  bool inActive = false;
  UserDBUtil db = UserDBUtil();
  YPassTaskSetting taskSetting = YPassTaskSetting();

  @override
  void initState() {
    super.initState();
    db.getDB();
    taskSetting.init();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!foreIsRun) {
      taskSetting.stopForegroundTask();
    } else {
      taskSetting.setContext(context);
      taskSetting.startForegroundTask();
    }

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
                onPressed: onClickOnOffButton,
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
  void onClickOnOffButton() async {
    if (db.isEmpty()) {
      CustomToast().showToast("사용자 정보 추가가 필요합니다.");
      debugPrint("DB 없다");
    } else {
      if (!inActive) {
        inActive = true;
        if (foreIsRun) {
          foreIsRun = false;
          taskSetting.stopForegroundTask();
        } else {
          foreIsRun = true;
          taskSetting.setContext(context);
          taskSetting.startForegroundTask();
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

  int evTime = 0;

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
    if (userDBUtil.isEmpty()) {
      CustomToast().showToast("사용자 정보 추가가 필요합니다.");
    } else {
      var user = userDBUtil.getUser();
      List addr = userDBUtil.getDong();
      debugPrint("Addr Dong Check : $addr");
      int nowTime = DateTime.now().millisecondsSinceEpoch;
      debugPrint("ev : $evTime, now : $nowTime");
      int sec = nowTime - evTime;
      if (sec > 20000) {
        evTime = nowTime;
        if (addr[0] == null || addr[1] == null) {
          String result = "";
          result = await http.homeEvCall(user.phoneNumber, addr[0], addr[1]);
          debugPrint("통신 결과 : $result");
        } else {
          CustomToast().showToast("\"집으로 호출\"기능은 관리자는 사용하실 수 없습니다.");
          debugPrint("관리자 체크");
        }
      } else {
        CustomToast().showToast("\"집으로 호출\"기능은 20초에 한번씩만 사용가능합니다. ${20 - (sec ~/ 1000)}초 후에 다시 사용 가능합니다.");
        debugPrint("20초 제한");
      }
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
      Text('$APP_VERSION v'),
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
