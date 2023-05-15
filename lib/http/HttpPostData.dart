import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:ypass/http/NetworkState.dart' as ns;
import 'package:ypass/http/StatisticsReporter.dart';

var client = HttpClient();
StatisticsReporter reporter = StatisticsReporter();

Map<String,String> ADDRESS_LIST = {
  "대전시 서구 관저중로 33" : "http://211.230.62.208:4400/TCPEVCALL",
  "충남 공주시 웅진절골3길 38" : "http://220.82.77.100:4001/TCPEVCALL",
  "경상북도 경산시 정평길 9-2" : "http://113.52.211.196:4001/TCPEVCALL",
  "동탄역센트럴예미지" : "http://211.221.88.71:4001/TCPEVCALL",
  "예미지트리플에듀" : "http://121.142.232.41:4001/TCPEVCALL"
};

Map<String,String> HOME_ADDRESS_LIST = {
  "대전시 서구 관저중로 33" : "http://211.230.62.208:4400/TCPEVCALL2",
  "충남 공주시 웅진절골3길 38" : "http://220.82.77.100:4001/TCPEVCALL2",
  "경상북도 경산시 정평길 9-2" : "http://113.52.211.196:4001/TCPEVCALL2",
  "동탄역센트럴예미지" : "http://211.221.88.71:4001/TCPEVCALL2",
  "예미지트리플에듀" : "http://121.142.232.41:4001/TCPEVCALL2"
};

//url 확인 필요 일단 긁어옴
String url = "https://xphub.xperp.co.kr/_clober/xpclober_api.svc";

late int httpType;
const int addUser = 0;
const int inoutUser = 1;
const int tempUser = 2;
const int getLicense = 3;
const int getUserData = 4;
const int evHome = 5;

late final int data;
late String netState;

//addUser = 0
Future<String> setUserDataPost(String phoneNumber) async {
  netState = await ns.checkNetwork();

  if (netState != '인터넷 연결 안됨') {
    httpType = addUser;

    http.Response response = await http.post(
        Uri.parse("$url/clober-approval"),
        body: <String, String> {
          "data" : <String, String> {
            "phone" : phoneNumber
          }.toString()
        }
    ).timeout(const Duration(seconds: 1));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "통신error";
    }
  } else {
    return "네트워크 연결 실패";
  }
}


//inoutUser = 1
Future<String> cloberPass(int type, int scanType) async {
  netState = await ns.checkNetwork();

  if (netState != '인터넷 연결 안됨') {
    httpType = tempUser;
    String userid = 'userData id가져와야함';
    //평균 RSSI = BLE 스캔시 얻은 max RSSI 값
    //마지막 0은 뭔지 확인 필요
    String rssi = '평균RSSI,MODEL,설정RSSI,0';
    String setRssi = '설정RSSI';
    String model = '휴대폰 기종';
    String brand = '확인중 휴대폰 브랜드 예상';

    //kind도 확인 예정 And, iOS 구분 예상
    http.Response response = await http.post(
        Uri.parse("$url/put-visitguest"),
        body: <String, String> {
          "id" : userid,
          "type" : type.toString(),
          "rssi" : rssi,
          "setRssi" : setRssi,
          "phone" : model,
          "kind" : "0",
          "brand" : brand
        }
    ).timeout(const Duration(seconds: 1));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "통신error";
    }
  } else {
    return "네트워크 연결 실패";
  }
}

//tempUser = 2
Future<String> setTempUser(String vphone, String vaddr, String sDate, String eDate) async {
  //유저 등록 확인 필요


  netState = await ns.checkNetwork();

  if (netState != '인터넷 연결 안됨') {
    httpType = tempUser;
    String phoneNumber = 'userData 번호가져와야함';

    http.Response response = await http.post(
        Uri.parse("$url/put-visitguest"),
        body: <String, String> {
          "data" : <String, String> {
            "phone" : phoneNumber,
            "v_phone" : vphone,
            "v_addr" : vaddr,
            "sDate" : sDate,
            "eDate" : eDate
          }.toString()
        }
    ).timeout(const Duration(seconds: 1));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "통신error";
    }
  } else {
    return "네트워크 연결 실패";
  }
}

//getLicense = 3
Future<String> userLicense(int type, int scanType) {
  return Future.value("false");
}

//getUserData = 4
Future<String> getUserDataPost(String phoneNumber) async {
  netState = await ns.checkNetwork();

  const Map<String, String> _JSON_HEADERS = {
    "content-type": "application/json"
  };

  if (netState != '인터넷 연결 안됨') {
    httpType = getUserData;

    String userPhoneNumber = '${phoneNumber.substring(0,3)}-${phoneNumber.substring(3,7)}-${phoneNumber.substring(7)}';
    Map<String, dynamic> sendData = {"data":"{'phone':'$userPhoneNumber'}"};
    debugPrint('Sending Data : ${sendData.toString()}');
    debugPrint('Encoded : ${json.encode(sendData)}');
    http.Response response = await http.post(
      Uri.parse("https://xphub.xperp.co.kr/_clober/xpclober_api.svc/clober-approval"),
      body: json.encode(sendData),
      headers: _JSON_HEADERS
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      debugPrint('Response Body : ${response.body}');
      return response.body;
    } else {
      debugPrint('Response Status : ${response.statusCode}');
      debugPrint('Response Body : ${response.body}');
      return "통신error";
    }
  } else {
    return "네트워크 연결 실패";
  }
}



//evHome = 5
//집에서 호출
Future<String> homeEvCall(String phoneNumber, String dong, String ho) async {
  netState = await ns.checkNetwork();

  if (netState != '인터넷 연결 안됨') {
    String url = "";
    httpType = evHome;

    //url = HOME_ADDRESS_LIST['유저주소'];
    final response = await http.get(Uri.parse("$url/$dong/$ho"));
    if (response.statusCode == 200) {
      //log 남기기 통신
      //reporter.sendReport(phoneNumber, dong, ho);
      return response.body;
    } else {
      //log 남기기 통신
      //reporter.sendError(cid, phoneNumber);
      return "통신error";
    }
  } else {
    return "네트워크 연결 실패";
  }
}

//밖에서 호출
Future<String> evCall(String cid, String phoneNumber) async {
  netState = await ns.checkNetwork();

  if (netState != '인터넷 연결 안됨') {
    String url = "";
    //httpType = getUser;

    //url = ADDRESS_LIST['유저주소'];
    final response = await http.get(Uri.parse("$url/$cid"));
    if (response.statusCode == 200) {
      //log 남기기 통신
      //reporter.sendReport(phoneNumber, dong, ho);
      return response.body;
    } else {
      //log 남기기 통신
      //reporter.sendError(cid, phoneNumber);
      return "통신error";
    }
  } else {
    return "네트워크 연결 실패";
  }
}

/* 더미 코드 (아마? 필요하면 구현)
Future<String> getUrl(int type, int scanType) {
  return Future.value("false");
}*/

/* 보류
Future<String> userInit(int type, int scanType) {
  return Future.value("false");
}*/
