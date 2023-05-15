import 'package:flutter/material.dart';
import 'package:ypass/constant/color.dart';
import 'package:ypass/screen/serve/Bar.dart';
import 'package:ypass/screen/serve/TopBar.dart';

import '../http/UserDataRequest.dart';


class UpdateUserDataScreen extends StatefulWidget {
  const UpdateUserDataScreen({Key? key}) : super(key: key);

  @override
  State<UpdateUserDataScreen> createState() => _UpdateUserDataScreenState();
}

class _UpdateUserDataScreenState extends State<UpdateUserDataScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MAIN_BACKGROUND_COLOR,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Bar(barSize: 10.0),
              const TopBar(title: '사용자 정보 수정'), // 상단 타이틀바
              _Middle(),
            ],
          ),
        ),
      ),
    );
  }
}



class _Middle extends StatelessWidget {
  TextEditingController phoneNumber = TextEditingController();
  TextEditingController authenticatioNumber = TextEditingController();

  _Middle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          const Text(
            "\"와이패스\" 앱은 핸드폰 번호를 사용하여 서비스를 이용하실 수 있습니다.\n핸드폰 번호는 입주민 확인을 위해서만 사용됩니다.",
            style: TextStyle(fontSize: 20),
          ),
          const Padding(padding: EdgeInsets.all(20)),
          _InputText(
            inputTitle: "전화번호",
            fieldText: phoneNumber,
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                print(phoneNumber.text);
              },
              style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))
                  ),
                backgroundColor: UPDATE_USER_DATA_BUTTON_COLOR,
              ),
              child: const Text('인증 번호 요청'),
            ),
          ),
          const Padding(padding: EdgeInsets.all(10)),
          _InputText(
            inputTitle: "인증번호",
            fieldText: authenticatioNumber,
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                print(authenticatioNumber.text);
              },
              style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))
                  ),
                  backgroundColor: BAR_COLOR,
              ),
              child: const Text('정보수정'),
            ),
          ),
        ],
      ),
    );
  }
}


// 텍스트 필드 위젯 함수
class _InputText extends StatelessWidget {
  final String inputTitle; // 텍스트 필드 제목
  final TextEditingController fieldText; // 텍스트 필트에 적은 텍스트 불러오기 용

  const _InputText(
      {Key? key, required String this.inputTitle, required this.fieldText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: TextField(
        decoration: InputDecoration(
            labelText: inputTitle,
            hintText: '$inputTitle를 입력 하세요.',
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
            )),
        keyboardType: TextInputType.number,
        controller: fieldText,
      ),
    );
  }
}
