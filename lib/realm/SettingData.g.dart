// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'SettingData.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

class SettingData extends _SettingData
    with RealmEntity, RealmObjectBase, RealmObject {
  SettingData(
    bool termsOfService,
    int userSetRange,
  ) {
    RealmObjectBase.set(this, 'termsOfService', termsOfService);
    RealmObjectBase.set(this, 'userSetRange', userSetRange);
  }

  SettingData._();

  @override
  bool get termsOfService =>
      RealmObjectBase.get<bool>(this, 'termsOfService') as bool;
  @override
  set termsOfService(bool value) =>
      RealmObjectBase.set(this, 'termsOfService', value);

  @override
  int get userSetRange => RealmObjectBase.get<int>(this, 'userSetRange') as int;
  @override
  set userSetRange(int value) =>
      RealmObjectBase.set(this, 'userSetRange', value);

  @override
  Stream<RealmObjectChanges<SettingData>> get changes =>
      RealmObjectBase.getChanges<SettingData>(this);

  @override
  SettingData freeze() => RealmObjectBase.freezeObject<SettingData>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(SettingData._);
    return const SchemaObject(
        ObjectType.realmObject, SettingData, 'SettingData', [
      SchemaProperty('termsOfService', RealmPropertyType.bool),
      SchemaProperty('userSetRange', RealmPropertyType.int),
    ]);
  }
}
