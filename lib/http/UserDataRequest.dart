import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:ypass/realm/UserDBUtil.dart';
import 'package:ypass/realm/db/IdArr.dart';
import 'package:ypass/realm/db/UserData.dart';
import 'package:ypass/screen/serve/Toast.dart';

import 'NetworkState.dart';
import 'StatisticsReporter.dart';
import 'package:http/http.dart' as http;



// 싱글톤
class UserDataRequest {
  static final UserDataRequest _dataRequest = UserDataRequest._internal();

  UserDataRequest._internal();

  factory UserDataRequest() {
    return _dataRequest;
  }

  // realm config 설정
  final configUser = Configuration.local([UserData.schema]);
  final configIdArr = Configuration.local([IdArr.schema]);


  // 유저 데이터 서버 호출 및 DB저장
  Future<bool> setUserData(String phoneNumber) async {

    debugPrint("66666");
    var netState = await checkNetwork();
    StatisticsReporter reporter = StatisticsReporter();

    const Map<String, String> JSON_HEADERS = {
      "content-type": "application/json"
    };

    if (netState != '인터넷 연결 안됨') {
      // 010AAAABBBB를 010-AAAA-BBBB형태로 전환
      String userPhoneNumber = '${phoneNumber.substring(0,3)}-${phoneNumber.substring(3,7)}-${phoneNumber.substring(7)}';

      Map<String, dynamic> sendData = {"data":"{'phone':'$userPhoneNumber'}"}; // 서버에 전송할 파라미터값

      // 서버에 데이터 요청
      http.Response response = await http.post(
          Uri.parse("https://xphub.xperp.co.kr/_clober/xpclober_api.svc/clober-approval"),
          body: json.encode(sendData),
          headers: JSON_HEADERS
      ).timeout(const Duration(seconds: 10));

      // POST 요청이 성공 했을 경우
      if (response.statusCode == 200) {


        debugPrint("77777");
        // var test = jsonDecode(response.body);
        // var test2 = test.toString().replaceAll('\'', '\"');
        // var test3 = jsonDecode(test2) as Map<String, dynamic>;
        // 위 내용과 jsonData과 동일
        var jsonData = (jsonDecode(jsonDecode(response.body).toString().replaceAll('\'', '"'))) as Map<String, dynamic>;


        if (jsonData['result'] == 0 || jsonData['result'] == '0') {
          CustomToast().showToast('등록된 사용자가 아닙니다. 관리실에 문의해주세요');
          return false;
        }
        var listArr = jsonData['listArr'][0];

        debugPrint("88888");
        // User Realm 불러오기
        UserDBUtil userDB = UserDBUtil();

        userDB.deleteDB(); // 기존 데이터 삭제
        userDB.createUserData(phoneNumber, listArr['addr'], listArr['type'], listArr['sDate'], listArr['eDate'], !(listArr['addr'].toString().contains('동'))); // 유저 데이터 저장
        //  IdArr (cloberid, userid, pk) 저장
        for (var idArrValue in listArr['idArr']) {
          userDB.createIDArr(IdArr(idArrValue['cloberid'].toString().toLowerCase(), idArrValue['userid'], idArrValue['pk']));
        }

        debugPrint("999999");
        String result;
        result = await reporter.sendReport(response.body, userPhoneNumber);
        debugPrint("통신 결과 : $result");

        debugPrint("10101010");
        return true;

      } else {

        debugPrint('Response Status : ${response.statusCode}');
        debugPrint('통신error');
        debugPrint('Response Body : ${response.body}');
        String result;
        result = await reporter.sendError("유저 정보 서버 통신 실패", phoneNumber);
        debugPrint("통신error : $result");

        return false;
      }
    } else {
      debugPrint('네트워크 연결 실패');
      CustomToast().showToast('인터넷 연결상태를 확인해 주세요.');
      return false;
    }
  }


}



var testIdArr = [
  {
    "userid":"0101010b356b",
    "pk":"Q7dcUMxkz1",
    "cloberid":"01010303"
  },
  {
    "userid":"0101010b3c13",
    "pk":"CnQ1RlSkVN",
    "cloberid":"01010304"
  },
  {
    "userid":"0101010b4238",
    "pk":"ZWqy2kR0oe",
    "cloberid":"01010305"
  },
  {
    "userid":"0101010b485e",
    "pk":"EfqK92J3hs",
    "cloberid":"01010306"
  },
  {
    "userid":"0101010b4f05",
    "pk":"pEDx7NGLfT",
    "cloberid":"01010307"
  },
  {
    "userid":"0101010b552b",
    "pk":"OpQiGj2efd",
    "cloberid":"01010308"
  },
  {
    "userid":"0101010b5b51",
    "pk":"72cz8PfVDW",
    "cloberid":"01010309"
  },
  {
    "userid":"0101010b6177",
    "pk":"Hut46PqVBs",
    "cloberid":"0101030a"
  },
  {
    "userid":"0101010b681e",
    "pk":"kK32RsEeGU",
    "cloberid":"0101030b"
  },
  {
    "userid":"0101010b746a",
    "pk":"DZy9f2pe8F",
    "cloberid":"0101030d"
  },
  {
    "userid":"0101010b7b11",
    "pk":"Aen4WFcfsh",
    "cloberid":"0101030e"
  },
  {
    "userid":"0101010c0237",
    "pk":"Wd1pXEmtb6",
    "cloberid":"0101030f"
  },
  {
    "userid":"0101010b6e44",
    "pk":"IZ83Eu5NKt",
    "cloberid":"0101030c"
  },
  {
    "userid":"0101010c085d",
    "pk":"RMp651VtQK",
    "cloberid":"01010310"
  },
  {
    "userid":"0101010c0f04",
    "pk":"ZcR7Og8zne",
    "cloberid":"01010311"
  },
  {
    "userid":"0101010c152a",
    "pk":"is52qAHKcv",
    "cloberid":"01010312"
  },
  {
    "userid":"0101010c1b50",
    "pk":"beVKRoLtnH",
    "cloberid":"01010313"
  },
  {
    "userid":"0101010c2176",
    "pk":"gpOYz5WHTn",
    "cloberid":"01010314"
  },
  {
    "userid":"0101010c281d",
    "pk":"VQFuixHP6S",
    "cloberid":"01010315"
  },
  {
    "userid":"0101010c2e43",
    "pk":"ie5M9DaFJg",
    "cloberid":"01010316"
  },
  {
    "userid":"0101010c3469",
    "pk":"impJSqj29R",
    "cloberid":"01010317"
  },
  {
    "userid":"0101010c3b10",
    "pk":"PIGHVNMtBC",
    "cloberid":"01010318"
  },
  {
    "userid":"0101010c4136",
    "pk":"DJ2NwhxrSK",
    "cloberid":"01010319"
  },
  {
    "userid":"0101010c475c",
    "pk":"XEJ7hrOksC",
    "cloberid":"0101031a"
  },
  {
    "userid":"0101010c4e03",
    "pk":"5wsJtXz8nU",
    "cloberid":"0101031b"
  },{
    "userid":"0101010c5429",
    "pk":"19eEQsH4CF",
    "cloberid":"0101031c"
  },
  {
    "userid":"0101010c5a4f",
    "pk":"nB4IA1Kv0X",
    "cloberid":"0101031d"
  }
];