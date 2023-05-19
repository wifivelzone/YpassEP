import 'package:realm/realm.dart';


part 'SettingData.g.dart';

@RealmModel()
class _SettingData {
  late bool termsOfService; // 약관 동의 확인 여부
  late int userSetRange; // 인증 범위 설정
  late bool autoFlowSelectState; // 층 버튼 자동 눌림 설정 상태
}