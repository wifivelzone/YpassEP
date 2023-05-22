import 'package:flutter/foundation.dart';
import 'package:realm/realm.dart';
import 'package:ypass/constant/MgrationVersion.dart';
import 'package:ypass/realm/db/IdArr.dart';
import 'package:ypass/realm/db/UserData.dart';

class UserDBUtil {
  static final UserDBUtil _dataRequest = UserDBUtil._internal();

  UserDBUtil._internal();

  factory UserDBUtil() {
    return _dataRequest;
  }

  var realmUser = Realm(Configuration.local([UserData.schema], schemaVersion: REALM_DB_VERSION));
  var realmIdArr = Realm(Configuration.local([IdArr.schema], schemaVersion: REALM_DB_VERSION));
  late RealmResults<UserData> temp1;
  late RealmResults<IdArr> temp2;



  /// Create
  void createUserData(String phoneNumber, String addr, String type, String sDate, String eDate) {
    realmUser.write(() {
      realmUser.deleteAll<UserData>(); // 기존 데이터 삭제
      realmUser.add(UserData(phoneNumber, addr , type, sDate, eDate));
    });
  }

  void createIDArr(IdArr idArr) {
    realmIdArr.write(() {
      realmIdArr.add(idArr);
    });
  }


  /// Read
  void getDB() {
    temp1 = realmUser.all<UserData>();
    temp2 = realmIdArr.all<IdArr>();
  }

  IdArr findCloberByCID(String cid) {
    var finds = temp2.query("cloberid == '$cid'");
    return finds[0];
  }

  UserData getUser() {
    return temp1[0];
  }

  //주소 ccc a동 b호 에서 동,호 숫자만[a,b] 가져오기
  List<String> getDong() {
    String addStr = getUser().addr;
    List<String> addrArr = addStr.split("::");
    if (kDebugMode){
      addrArr[0] += "101동 301호"; //test Code
    }
    List<String> split = addrArr[0].split(" ");
    String dong = "";
    String ho = "";
    if (split.length - 2 > 0 && split[split.length - 2].contains("동")) {
      dong = split[split.length - 2].replaceAll("동", "");
      ho = split[split.length - 1].replaceAll("호", "");
    }
    return [dong, ho];
  }

  //주소 ccc a동 b호 에서 동,호를 뺀 주소만 가져오기 (ccc)
  String getAddr() {
    String result = "";
    String addStr = getUser().addr;
    List<String> addrArr = addStr.split("::");
    if (kDebugMode){
      addrArr[0] += "101동 301호"; //test Code
    }
    debugPrint("Addr Array Check : ${addrArr}");
    List<String> split = addrArr[0].split(" ");
    debugPrint("Addr Check : ${split}");
    for (int i = 0; i < split.length-2; i++) {
      debugPrint("Addr Check : ${split[i]}");
      result += split[i];
      if (i!=split.length-3) {
        result += " ";
      }
    }
    return result;
  }

  //user가 사용 가능한 출입 Clober list의 첫번째 Clober 가져오기
  String getFirstClober() {
    return temp2[0].cloberid;
  }


  /// Delete
  void deleteDB() {
    realmUser.write(() {
      realmUser.deleteAll<UserData>();
    });
    realmIdArr.write(() {
      realmIdArr.deleteAll<IdArr>();
    });
  }

  /// 기타
  bool isEmpty() {
    return temp1.isEmpty && temp2.isEmpty;
  }







}