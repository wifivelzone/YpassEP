import 'package:flutter/material.dart';
import 'package:ypass/screen/serve/Bar.dart';
import 'package:ypass/screen/serve/LinePadding.dart';
import 'package:ypass/screen/serve/TopBar.dart';

import '../constant/color.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MAIN_BACKGROUND_COLOR,
      body: SafeArea(
        child: Column(
          children: [
            const Bar(barSize: 10.0),
            const TopBar(title: '설정'), // 상단 타이틀바
            _Middle()
          ],
        ),
      ),
    );
  }
}

class _Middle extends StatefulWidget {
  double stateNumber = 20;

  _Middle({Key? key}) : super(key: key);

  @override
  State<_Middle> createState() => _MiddleState();
}

class _MiddleState extends State<_Middle> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '인증범위 설정',
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          const LinePadding(value: 10),
          Text(
            '현재 설정된 단계는 : ${widget.stateNumber}',
            style: TextStyle(color: UPDATE_USER_DATA_BUTTON_COLOR),
          ),
          const LinePadding(value: 20),
          Row(
            children: [
              Text('0'),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    // trackHeight: 10.0,

                    activeTrackColor: BAR_COLOR,
                    inactiveTrackColor: Colors.black38,
                    thumbColor: Colors.red,
                    activeTickMarkColor: BAR_COLOR,
                    inactiveTickMarkColor: Colors.white,
                  ),
                  child: Slider(
                    min: 0.0,
                    max: 20.0,
                    value: widget.stateNumber,
                    divisions: 20,
                    label: '${widget.stateNumber}',
                    onChanged: (value) {
                      setState(() {
                        widget.stateNumber = value;
                      });
                    },
                  ),
                ),
              ),
              Text('20')
            ],
          ),
          const LinePadding(value: 10),
          const Text(
            '인증단계가 높을수록 멀리서 인증됩니다.',
            style: TextStyle(color: UPDATE_USER_DATA_BUTTON_COLOR),
          ),
          const LinePadding(value: 60),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                print('');
              },
              style: ElevatedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                backgroundColor: BAR_COLOR,
              ),
              child: const Text('설정 저장'),
            ),
          ),
        ],
      ),
    );
  }
}
