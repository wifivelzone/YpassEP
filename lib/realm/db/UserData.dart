import 'package:realm/realm.dart';

part 'UserData.g.dart';

// realm에 저장된 유저 정보들
@RealmModel()
class _UserData {
  late String phoneNumber;  // 핸드폰 번호
  late String addr;         // 집주소
  late String type;         // 0:입주자, 1:방문자
  late String sDate;        // 방문 가능 시작 시간
  late String eDate;        // 방문 가능 종료 시간
}