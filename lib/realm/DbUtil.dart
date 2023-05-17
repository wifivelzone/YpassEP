import 'package:realm/realm.dart';
import 'package:ypass/realm/IdArr.dart';
import 'package:ypass/realm/UserData.dart';

class DbUtil {
  var realmUser = Realm(Configuration.local([UserData.schema]));
  var realmIdArr = Realm(Configuration.local([IdArr.schema]));
  late RealmResults<UserData> temp1;
  late RealmResults<IdArr> temp2;

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
}