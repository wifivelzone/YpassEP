import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ypass/screen/SetttingScreen.dart';
import 'package:ypass/screen/UpdateUserDataScreen.dart';
import 'package:ypass/screen/serve/Bar.dart';

import '../constant/color.dart';

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
          children: [
            Bar(barSize: 5.0),
            Top(),
            Bar(barSize: 5.0),
            Middle(),
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
                  print('222');
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

class Middle extends StatelessWidget {
  const Middle({Key? key}) : super(key: key);

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
          child: MiddleButtonImg(),
        ),
      ),
    );
  }
}

class MiddleButtonImg extends StatelessWidget {
  BuildContext? context;

  MiddleButtonImg({Key? key}) : super(key: key);


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
    print(1);
  }

  // 사용자 정보 수정 버튼 클릭시
  _clickedUpdateUserDataBtn() {
    if (this.context != null) {
      Navigator.push(
        this.context!,
          MaterialPageRoute(
            builder: (BuildContext contex) => UpdateUserDataScreen(),
        ),
      );
    }
  }

  // 설정 버튼 클릭시
  void clickedSettingBtn() {
    if (this.context != null) {
      Navigator.push(
        this.context!,
        MaterialPageRoute(
          builder: (BuildContext contex) => const SettingScreen(),
        ),
      );
    }
  }

  // 문의 버튼 클릭시
  clickedQuestionBtn() {
    print(4);
  }
}


/** ---------------------------------------------------- */
/** --------------------   하단 부분  --------------------- */
/// -------------------------------------------------------

class Bottom extends StatelessWidget {
  const Bottom({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
      child: Text("v.10\n22"),
    );
  }
}

