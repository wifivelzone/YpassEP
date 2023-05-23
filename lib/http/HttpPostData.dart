import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:ypass/http/NetworkState.dart' as ns;
import 'package:ypass/http/StatisticsReporter.dart';
import 'package:ypass/http/HttpType.dart';
import 'package:ypass/realm/SettingDBUtil.dart';
import 'package:ypass/realm/UserDBUtil.dart';

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

late final int data;
late String netState;

//inoutUser = 1
Future<String> cloberPass(int pass, String cid, String maxRssi) async {
  netState = await ns.checkNetwork();

  if (netState != '인터넷 연결 안됨') {
    httpType = HttpType.tempUser;
    DeviceInfoPlugin device = DeviceInfoPlugin();
    UserDBUtil db = UserDBUtil();
    db.getDB();
    SettingDataUtil set = SettingDataUtil();
    var find = db.findCloberByCID(cid);

    String userid = find.userid;
    List listUserid = [userid.substring(0,2), userid.substring(2,4), userid.substring(4,6), userid.substring(6,8), userid.substring(8,10), userid.substring(10,12)];
    List convetedList = listUserid.map((number) => int.parse(number, radix: 16).toString()).toList();
    String isAnd = "0";

    String model = '휴대폰 기종';
    String brand = '확인중 휴대폰 브랜드 예상';
    if (Platform.isIOS) {
      isAnd = "1";
      IosDeviceInfo iosInfo = await device.iosInfo;
      model = iosInfo.model;
      brand = "Apple";
    } else {
      AndroidDeviceInfo andInfo = await device.androidInfo;
      model = andInfo.model;
      brand = andInfo.brand;
    }
    //평균 RSSI = BLE 스캔시 얻은 max RSSI 값
    //마지막 0은 뭔지 확인 필요
    String rssi = "$maxRssi,$model,${-75.5-set.getUserSetRange()},$isAnd";
    String setRssi = "${-75.5-set.getUserSetRange()}";
    String conUserId = "";
    for (String i in convetedList) {
      conUserId += "$i,";
    }
    conUserId = conUserId.substring(0,conUserId.length-1);

    //type은 pass 성공하면 0으로
    //kind도 확인 예정 And, iOS 구분 예상
    http.Response response = await http.post(
        Uri.parse("http://211.46.227.157:4001/POSTTEST"),
        body: <String, String> {
          "id" : conUserId,
          "type" : (pass-1).toString(),
          "rssi" : rssi,
          "setRssi" : setRssi,
          "phone" : model,
          "kind" : isAnd,
          "brand" : brand
        }
    ).timeout(const Duration(seconds: 1));
    if (response.statusCode == 200) {
      String result;
      if (response.body == "") {
        result = "통신 성공";
      } else {
        result = response.body;
      }
      return result;
    } else {
      return "통신error : ${response.body}, ${response.statusCode}";
    }
  } else {
    return "네트워크 연결 실패";
  }
}
/*
//tempUser = 2
Future<String> setTempUser(String vphone, String vaddr, String sDate, String eDate) async {
  //유저 등록 확인 필요


  netState = await ns.checkNetwork();

  if (netState != '인터넷 연결 안됨') {
    httpType = HttpType.tempUser;
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
}*/

//evHome = 5
//집에서 호출
Future<String> homeEvCall(String phoneNumber, String dong, String ho) async {
  netState = await ns.checkNetwork();

  UserDBUtil db = UserDBUtil();
  db.getDB();
  if (netState != '인터넷 연결 안됨') {
    String? url = "";
    httpType = HttpType.evHome;

    String userAddr = db.getAddr();
    url = HOME_ADDRESS_LIST[userAddr];
    final response = await http.get(Uri.parse("$url/$dong/$ho"));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      //log 남기기 통신
      String result;
      result = await reporter.sendError("승강기 통신 실패", phoneNumber);
      return "통신error : $result";
    }
  } else {
    return "네트워크 연결 실패";
  }
}

//밖에서 호출
Future<String> evCall(String cid, String phoneNumber) async {
  netState = await ns.checkNetwork();

  UserDBUtil db = UserDBUtil();
  db.getDB();
  if (netState != '인터넷 연결 안됨') {
    String? url = "";

    String userAddr = db.getAddr();
    url = ADDRESS_LIST[userAddr];
    final response = await http.get(Uri.parse("$url/$cid"));
  if (response.statusCode == 200) {
    return response.body;
  } else {
    //log 남기기 통신
    String result;
    result = await reporter.sendError("승강기 통신 실패", phoneNumber);
    return "통신error : $result";
  }
    //return "통신 테스트";
  } else {
    return "네트워크 연결 실패";
  }
}

Future<String> evCallGyeongSan(String phoneNumber, bool isInward, String cloberId, String ho) async {
  netState = await ns.checkNetwork();

  if (netState != '인터넷 연결 안됨') {
    String url = "";
    httpType = HttpType.evHome;

    UserDBUtil userDB = UserDBUtil();
    userDB.getDB();
    SettingDataUtil db = SettingDataUtil();
    String inClober = db.getLastInCloberID();
    if (inClober == "") {
      inClober = userDB.getFirstClober();
    }
    if (isInward) {
      url = "http://113.52.211.196:4001/TCPCARCALL";
      final response =
          await http.get(Uri.parse("$url/$inClober/$cloberId/$ho"));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        //log 남기기 통신
        String result;
        result = await reporter.sendError("승강기 통신 실패", phoneNumber);
        return "통신error : $result";
      }
    } else {
      url = "http://113.52.211.196:4001/TCPCARCALL2";
      final response =
      await http.get(Uri.parse("$url/$inClober/$cloberId"));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        //log 남기기 통신
        String result;
        result = await reporter.sendError("승강기 통신 실패", phoneNumber);
        return "통신error : $result";
      }
    }
  } else {
    return "네트워크 연결 실패";
  }
}
