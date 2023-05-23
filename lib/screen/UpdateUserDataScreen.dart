import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ypass/constant/CustomColor.dart';
import 'package:ypass/screen/serve/Bar.dart';
import 'package:ypass/screen/serve/Toast.dart';
import 'package:ypass/screen/serve/TopBar.dart';

import 'package:fluttertoast/fluttertoast.dart';

import '../constant/Exception.dart';
import '../http/UserDataRequest.dart';

// 사용자 정보 수정 페이지
class UpdateUserDataScreen extends StatefulWidget {
  const UpdateUserDataScreen({Key? key}) : super(key: key);

  @override
  State<UpdateUserDataScreen> createState() => _UpdateUserDataScreenState();
}

class _UpdateUserDataScreenState extends State<UpdateUserDataScreen> {

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MAIN_BACKGROUND_COLOR,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Bar(barSize: 10.0),
              TopBar(title: '사용자 정보 수정'), // 상단 타이틀바
              _Middle(),
            ],
          ),
        ),
      ),
    );
  }
}


class _Middle extends StatefulWidget {

  const _Middle({Key? key}) : super(key: key);

  @override
  State<_Middle> createState() => _MiddleState();
}

class _MiddleState extends State<_Middle> {
  TextEditingController textFieldPhoneNumber = TextEditingController(); // 핸드폰번호 입력 텍스트 필드
  TextEditingController authenticatioNumber = TextEditingController(); // 인증번호 입력 텍스트 필드

  FirebaseAuth auth = FirebaseAuth.instance; // 파이어 베이스

  late String phoneNumbe; // 유저 전화번호

  // 인증 번호 여러번 요청 방지 용도
  // true : 인증 문자 요청 가능
  // false : 인증 문자 요청 불가능
  bool waitPhoneAuth = true;
  bool sendSMS = false; // 문자가 전송 되었는지 판단
  late String _verificationId; // 문자 인증 코드

  bool authSuccess = true; // 인증 성공 여부

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
            fieldText: textFieldPhoneNumber,
          ),
          SizedBox(
            width: MediaQuery
                .of(context)
                .size
                .width,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                requestAuthNumber(); // 파이어베이스 인증 문자요청
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
          sendSMS ? _InputText(
            inputTitle: "인증번호",
            fieldText: authenticatioNumber,
          ) : const Padding(padding: EdgeInsets.all(1)),
          sendSMS ? SizedBox(
            width: MediaQuery
                .of(context)
                .size
                .width,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                debugPrint(authenticatioNumber.text);
                clickedUpdateInformationButton();
              },
              style: ElevatedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))
                ),
                backgroundColor: BAR_COLOR,
              ),
              child: const Text('정보수정'),
            ),
          ) : const Padding(padding: EdgeInsets.all(1)),
        ],
      ),
    );
  }

  // 파이어베이스 인증 문자요청
  Future<void> requestAuthNumber() async {
    // 문자 요청을 처음 하는 경우
    if (waitPhoneAuth) {
      String num = textFieldPhoneNumber.text.substring(1); // 010AAAABBBB -> 10AAAABBBB
      phoneNumbe = textFieldPhoneNumber.text; // 전화 번호 저장

      // 문자 요청
      await auth.verifyPhoneNumber(
        phoneNumber: "+82 $num", // 인증 요청할 전화번호
        timeout: const Duration(seconds: 120),// 2분 안에 인증 코드를 입력해야됨
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android only
          await auth
              .signInWithCredential(credential)
              .then((_) => debugPrint('ttt'));
        },
        // 문지 전송 실패시
        verificationFailed: (FirebaseAuthException e) {
          sendSMSFail(e);
        },
        // 문자 전송 성공시
        codeSent: (String verificationId, int? resendToken) async {
          sendSMSSuccess(verificationId);
        },
        // 타임 아웃 시
        codeAutoRetrievalTimeout: (String verificationId) {
          sendSMSTimeout();
        },
      );
    } else {
      CustomToast().showToast('이미 요청 하였습니다.');
    }
  }

  // 문지 전송 실패시
  sendSMSFail(FirebaseAuthException e) {
    debugPrint('문자 전송 에러 메세지');
    debugPrint(e.toString());
    debugPrint('------------------');
    CustomToast().showToast('잘못된 전화번호 입니다.');
    waitPhoneAuth = true;
  }

  // 문자 전송 성공시
  sendSMSSuccess(String verificationId) {
    setState(() {
      _verificationId = verificationId;
      sendSMS = true;
    });
  }

  // 타임 아웃 시
  sendSMSTimeout() {
    CustomToast().showToast('시간이 초과되었습니다. 다시 인증번호를 요청해주세요.');
    waitPhoneAuth = true;
  }

  // 정보 수정 버튼을 클릭시
  Future <void> clickedUpdateInformationButton() async {
    if (await compareVerificationID()) {
      UserDataRequest().setUserData(phoneNumbe); // 유저 정보 업데이트
      CustomToast().showToast('정보 수정이 완료되었습니다.');
      Navigator.pop(context); // 메인 화면으로 이동
    }
  }


  // 인증코드 동일한지 비교
  Future<bool> compareVerificationID() async {
    try {
      // 사용자가 입력한 인증코드와 실제 인증코드가 동일한지 비교
      PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(verificationId: _verificationId, smsCode: authenticatioNumber.text);
      await auth.signInWithCredential(phoneAuthCredential);

      return true;
    } catch (e) {
      if (e.toString() == INVALID_SMS_CODE) {
        CustomToast().showToast('인증번호가 다릅니다.');
      } else if (e.toString() == EXPIRED_SMS_CODE) {
        CustomToast().showToast('해당 코드가 만료되었습니다. 다시 인증번호를 요청해주세요.');
      } else {
        CustomToast().showToast('잘못된 접근입니다. 다시 시도해주세요.');
      }

      return false;
    }
  }
}


// 텍스트 필드 위젯 함수
class _InputText extends StatelessWidget {
  final String inputTitle; // 텍스트 필드 제목
  final TextEditingController fieldText; // 텍스트 필트에 적은 텍스트 불러오기 용

  const _InputText(
      {Key? key, required this.inputTitle, required this.fieldText})
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
