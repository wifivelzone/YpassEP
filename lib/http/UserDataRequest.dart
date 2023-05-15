import 'dart:convert';

import 'package:flutter/cupertino.dart';

import 'NetworkState.dart';
import 'package:http/http.dart' as http;

// 싱글톤
class UserDataRequest {
  static final UserDataRequest _dataRequest = UserDataRequest._internal();

  UserDataRequest._internal();

  factory UserDataRequest() {
    return _dataRequest;
  }


  Future<void> getUserData(String phoneNumber) async {
    String netState = await checkNetwork();

    if ('인터넷 연결 안됨' == netState) {
      debugPrint('사용자 등록은 네트워크 연결이 되어있어야 가능합니다.');
      return ;
    }

    // 010AAAABBBB를 010-AAAA-BBBB로 전환
    String userPhoneNumber = '${phoneNumber.substring(0,3)}-${phoneNumber.substring(3,7)}-${phoneNumber.substring(7)}';
    print(userPhoneNumber);
    var url = Uri.parse('https://xphub.xperp.co.kr/_clober/xpclober_api.svc/clober-approval');
    String jsonData = {'phone': '$userPhoneNumber'}.toString();
    /*final items =
      [{'id': '1', 'title': 'Item 1'}];*/

    //print(json.encode(items).runtimeType);

    // print(json_data);

    var response = await http.post(url, body: jsonData);

    print(response.statusCode);
    print(response.body);
    // for()

  }


}

class UserPhoneNumber {
  late String phone;

  UserPhoneNumber.init(String phone) {
    this.phone = phone;
  }
}