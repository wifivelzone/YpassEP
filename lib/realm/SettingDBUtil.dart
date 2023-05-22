import 'package:realm/realm.dart';
import 'package:ypass/constant/MgrationVersion.dart';
import 'package:ypass/realm/db/SettingData.dart';


// 싱글톤
class SettingDataUtil {
  static final SettingDataUtil _dataRequest = SettingDataUtil._internal();

  SettingDataUtil._internal();

  factory SettingDataUtil() {
    return _dataRequest;
  }

  final _realm = Realm(Configuration.local([SettingData.schema], schemaVersion: REALM_DB_VERSION)); // DB 설정
  late SettingData _settingData; // DB에 저장된 SettingData 값


  /// Create
  void createSettingData(bool termsOfService, int userSetRange, bool autoFlowState, bool stateOnOff, String lastInCloberID) {
    _realm.write(() {
      deleteSettingData();
      _realm.add(SettingData(termsOfService, userSetRange, autoFlowState, stateOnOff, lastInCloberID));
    });
    _settingData = _realm.all<SettingData>()[0];
  }


  /// Read
  SettingData getSettingData() {
    return _settingData;
  }

  bool getTermsOfService() {
    return _settingData.termsOfService;
  }

  int getUserSetRange() {
    return _settingData.userSetRange;
  }

  bool getAutoFlowSelectState() {
    return _settingData.autoFlowSelectState;
  }

  String getLastInCloberID() {
    return _settingData.lastInCloberID;
  }


  /// Update
  void setTermsOfService(bool termsOfService) {
    _realm.write(() => _settingData.termsOfService = termsOfService);
  }

  void setUserSetRange(int userSetRange) {
    _realm.write(() => _settingData.userSetRange = userSetRange);
  }

  void setAutoFlowSelectState(bool autoFlowSelectState) {
    _realm.write(() => _settingData.autoFlowSelectState = autoFlowSelectState);
  }

  void setLastInCloberID(String lastInCloberID) {
    _realm.write(() => _settingData.lastInCloberID = lastInCloberID);
  }


  /// Delete
  // 아마 사용 할일 없을거같음
  void deleteSettingData() {
    _realm.write(() => _realm.deleteAll<SettingData>());
  }



  /// 기타
  bool isEmpty() {
    return _realm.all<SettingData>().isEmpty;
  }




}