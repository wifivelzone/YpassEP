import 'package:realm/realm.dart';
import 'package:ypass/realm/IdArr.dart';
import 'package:ypass/realm/UserData.dart';
import 'package:ypass/realm/SettingData.dart';

class DbUtil {
  static final DbUtil _dataRequest = DbUtil._internal();

  DbUtil._internal();

  factory DbUtil() {
    return _dataRequest;
  }

  var realmUser = Realm(Configuration.local([UserData.schema]));
  var realmIdArr = Realm(Configuration.local([IdArr.schema]));
  var realmSetting = Realm(Configuration.local([SettingData.schema]));
  late RealmResults<UserData> temp1;
  late RealmResults<IdArr> temp2;
  late RealmResults<SettingData> temp3;

  void getDB() {
    temp1 = realmUser.all<UserData>();
    temp2 = realmIdArr.all<IdArr>();
  }

  void getSetting() {
    temp3 = realmSetting.all<SettingData>();
  }

  IdArr findCloberByCID(String cid) {
    var finds = temp2.query("cloberid == '$cid'");
    return finds[0];
  }

  UserData getUser() {
    return temp1[0];
  }

  List<String> getAddr() {
    String addStr = getUser().addr;
    List<String> addrArr = addStr.split("::");
    //                        addrArr[0] += " 101동 301호"; //test Code
    List<String> split = addrArr[0].split(" ");
    String dong = "";
    String ho = "";
    if (split.length - 2 > 0 && split[split.length - 2].contains("동")) {
      dong = split[split.length - 2].replaceAll("동", "");
      ho = split[split.length - 1].replaceAll("호", "");
    }
    return [dong, ho];
  }

  List<bool> isValid() {
    List<bool> result = [temp1.isNotEmpty, temp2.isNotEmpty];
    return result;
  }
  bool isValidSetting() {
    bool result = temp3.isNotEmpty;
    return result;
  }

  void deleteDB() {
    realmUser.write(() {
      realmUser.deleteAll<UserData>();
    });
    realmIdArr.write(() {
      realmIdArr.deleteAll<IdArr>();
    });
  }
}