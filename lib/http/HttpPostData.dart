import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:ypass/http/NetworkState.dart' as ns;

var client = HttpClient();
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
const int getUser = 0;
const int postDATA = 1;
const int postSOS = 2;

late final int data;
late String netState;

Future<String> getUserPost(String writetel, String phonetel) async {
  netState = await ns.checkNetwork();

  if (netState != '인터넷 연결 안됨') {
    httpType = getUser;

    //phonetel = phonetel.replaceAll("-", "");
    phonetel = writetel;

    http.Response response = await http.post(
        Uri.parse(userUrl),
        body: <String, String> {
          "tel" : writetel,
          "Ptel" : phonetel
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

Future<String> postUserData(String wid, String lat, String lon, String step, String cid, String rssi, String bat, String model, String acc, String alt) async {
  ns.checkNetwork().then((value) {
    netState = value;
  });

  if (netState != '인터넷 연결 안됨') {
    httpType = postDATA;

    http.Response response = await http.post(
        Uri.parse(userUrl),
        body: <String, String> {
          "wid" : wid,
          "lat" : lat,
          "lon" : lon,
          "step" : step,
          "cid" : cid,
          "rssi" : rssi,
          "bat" : bat,
          "modelName" : model,
          "acc" : acc,
          "alt" : alt
        }
    ).timeout(const Duration(seconds: 1));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "error";
    }
  } else {
    return "네트워크 연결 실패";
  }
}

Future<String> postSOSData(String wid, String lat, String lon, String cid, String rssi, String bat) async {
  ns.checkNetwork().then((value) {
    netState = value;
  });

  if (netState != '인터넷 연결 안됨') {
    httpType = postSOS;

    http.Response response = await http.post(
        Uri.parse(userUrl),
        body: <String, String>{
          "wid": wid,
          "lat": lat,
          "lon": lon,
          "cid": cid,
          "rssi": rssi,
          "bat": bat,
        }
    ).timeout(const Duration(seconds: 1));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "error";
    }
  } else {
    return "네트워크 연결 실패";
  }
}