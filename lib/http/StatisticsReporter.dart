import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:ypass/http/NetworkState.dart' as ns;

class StatisticsReporter {
  var client = HttpClient();

  String reportUrl = "http://211.46.227.157:4001/userLog";
  String errorUrl = "http://211.46.227.157:4001/ypasserrorLog";
  late String netState;

//집에서 호출
  Future<String> sendReport(String phoneNumber, String dong, String ho) async {
    netState = await ns.checkNetwork();

    if (netState != '인터넷 연결 안됨') {
      String url = reportUrl;

      final response = await http.get(Uri.parse("$url/$dong/$ho"));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        return "통신error";
      }
    } else {
      return "네트워크 연결 실패";
    }
  }

//밖에서 호출
  Future<String> sendError(String cid, String phoneNumber) async {
    netState = await ns.checkNetwork();

    if (netState != '인터넷 연결 안됨') {
      String url = errorUrl;

      final response = await http.get(Uri.parse("$url/$cid"));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        return "통신error";
      }
    } else {
      return "네트워크 연결 실패";
    }
  }
}