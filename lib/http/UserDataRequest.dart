import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:realm/realm.dart';
import 'package:ypass/realm/IdArr.dart';
import 'package:ypass/realm/UserData.dart';

import 'NetworkState.dart';
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
  Future<void> setUserData(String phoneNumber) async {
    var netState = await checkNetwork();

    const Map<String, String> _JSON_HEADERS = {
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
          headers: _JSON_HEADERS
      ).timeout(const Duration(seconds: 10));

      // POST 요청이 성공 했을 경우
      if (response.statusCode == 200) {
        // var test = jsonDecode(response.body);
        // var test2 = test.toString().replaceAll('\'', '\"');
        // var test3 = jsonDecode(test2) as Map<String, dynamic>;
        // 위 내용과 jsonData과 동일
        var jsonData = (jsonDecode(jsonDecode(response.body).toString().replaceAll('\'', '\"'))) as Map<String, dynamic>;
        var listArr = jsonData['listArr'][0];

        // Realm 불러오기
        var realmUser = Realm(configUser);
        var realmIdArr = Realm(configIdArr);

        // 유저 데이터 저장
        realmUser.write(() {
          realmUser.deleteAll<UserData>(); // 기존 데이터 삭제
          realmUser.add(UserData(listArr['num'], listArr['addr'] , listArr['type'], listArr['sDate'], listArr['eDate']));
        });

        //  IdArr cloberid, userid, pk 저장
        realmIdArr.write(() {
          realmIdArr.deleteAll<IdArr>(); // 기존 데이터 삭제
          for (var idArrValue in listArr['idArr']) {
            realmIdArr.add(IdArr(idArrValue['cloberid'], idArrValue['userid'], idArrValue['pk']));
          }
        });


      } else {
        debugPrint('Response Status : ${response.statusCode}');
        debugPrint('통신error');
        // debugPrint('Response Body : ${response.body}');
      }
    } else {
      debugPrint('네트워크 연결 실패');
    }
  }


}



