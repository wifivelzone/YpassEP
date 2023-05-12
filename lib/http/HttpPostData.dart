import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:ypass/http/NetworkState.dart' as ns;
import 'package:ypass/http/StatisticsReporter.dart';

var client = HttpClient();
StatisticsReporter reporter = StatisticsReporter();
const String postUrl = "https://ppssmposition.posco.co.kr:6003/access/posco_http";
const String userUrl = "https://ppssmposition.posco.co.kr:6003/access/workerinfo";
const String sosUrl = "https://ppssmposition.posco.co.kr:6003/access/send_signal";

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

late int httpType;
const int addUser = 0;
const int inoutUser = 1;
const int tempUser = 2;
const int getLicense = 3;
const int getUserData = 4;
const int evHome = 5;

late final int data;
late String netState;

Future<String> cloberPass(int type, int scanType) {
  return Future.value("false");
}

Future<String> setTempUser(int type, int scanType) {
  return Future.value("false");
}

Future<String> userInit(int type, int scanType) {
  return Future.value("false");
}

//
Future<String> getUrl(int type, int scanType) {
  return Future.value("false");
}

//집에서 호출
Future<String> homeEvCall(String phoneNumber, String dong, String ho) async {
  netState = await ns.checkNetwork();

  if (netState != '인터넷 연결 안됨') {
    String url = "";
    httpType = evHome;

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
