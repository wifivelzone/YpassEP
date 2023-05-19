import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:ypass/http/HttpPostData.dart' as http;
import 'package:ypass/http/Encryption.dart';
import 'package:ypass/realm/UserDBUtil.dart';

class BleScanService {
  //instance 가져오기
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  //스캔 결과 list
  List<ScanResult> scanResultList = [];
  //스캔 중인지 확인하는 stram
  late StreamSubscription subscription;
  late StreamSubscription resStream;
  //찾은 clober 저장하는 list
  Map<String, List> cloberList = {};

  //지금 스캔 중인가?
  bool _isScanning = false;

  //현재 확인 중인 clober의 값들
  late String cid;
  late num rssi;
  late String bat;

  //RSSI가 가장 커서 따로 저장한 clober 값들
  late String maxCid;
  late num maxRssi;
  late String maxBat;
  //RSSI MAX인 device 정보
  late ScanResult maxR;

  late int k1;
  late int k2;

  final String notFound = "none";
  late Encryption enc;
  DbUtil db = DbUtil();

  //현재 스캔 중인지 확인함
  initBle() {
    db.getDB();
    subscription = flutterBlue.isScanning.listen((isScanning) {
      _isScanning = isScanning;
    });
  }

  //initble의 스캔 여부 확인하는 listen 종료 (안해주면 더미로 남음)
  disposeBle() {
    subscription.cancel();
    resStream.cancel();
  }

  //스캔 시작 .then이나 스캔 성공 여부 확인용 Future<bool>
  Future<bool> scan() async {
    Future<bool>? returnValue;
    clearMax();
    //이미 스캔 중인지 확인
    if (!_isScanning) {
      //기존 scan list 초기화
      scanResultList.clear();
      //스캔 시작
      flutterBlue.startScan(
          //성능 설정
          scanMode: ScanMode.lowLatency,
          //중복 scan 가능 설정
          allowDuplicates: true,
          //UUID filter 설정
          withServices: [Guid("00003559-0000-1000-8000-00805F9B34FB")],
          //시간초 설정 (4초)
          timeout: const Duration(seconds: 1)
      );
      //스캔 결과 (list형태)가 나오면 가져와서 저장
      int counter = 0;
      resStream = flutterBlue.scanResults.listen((results) {
        counter++;
        debugPrint("Scan Counter : ${counter}");
        scanResultList = results;
        debugPrint("Scan Length : ${scanResultList.length}");
        for(ScanResult res in scanResultList) {
          if (cloberList[res.device.id.toString()] == null) {
            cloberList.addEntries({"${res.device.id}" : [res.rssi]}.entries);
          } else {
            cloberList[res.device.id.toString()]?.add(res.rssi);
          }
        }
        //searchClober();
      });
      returnValue = Future.value(true);
    } else {
      //이미 작동 중이었으면 멈춤
      flutterBlue.stopScan();
      returnValue = Future.value(false);
    }

    return returnValue;
  }

  //스캔 중단
  void stopScan() {
    flutterBlue.stopScan();
    resStream.cancel();
  }

  //scan 결과 중에 clober 찾기
  Future<bool> searchClober() async {
    Future<bool>? returnValue;
    int forwardRssi = -100;
    int backRssi = -100;
    //기존 RSSI MAX 값들 초기화
    for (ScanResult res in scanResultList) {
      //ScanResult.advertisementData.manufactureData에 회사 확인이나 CID 등등 값들 있음 (공유되는 Clober 이미지 참고)
      var manu = res.advertisementData.manufacturerData;

      //map의 형태로 반환됨
      if(manu.keys.toList().isNotEmpty){
        //주의
        //이미지 기준 byte 11 부터 시작함 (회사코드 L 부분 / Y5LZ 중에)
        //Y5 값(9~10byte)은 map의 key값으로 배정됨
        //정확한 이유는 아직 못 찾음 (패키지 내용 확인 필요)

        // 9, 10byte값 map key로 가져오기
        // Y = 0x59 , 5 = 0x35
        // 13657 -> 3559 (dec to hex) -> 5 Y
        // key 값이 왜 10,9 byte 역순인 이유도 정확히 파악 안됨
        int a = manu.keys.toList().first;
        List code = [manu[a]?[0], manu[a]?[1]];
        List coop = [76, 90];

        if(listEquals(code, coop) && a == 13657){
          debugPrint("yes Clober");
        } else {
          debugPrint("no Clober");
          returnValue = Future.value(false);
        }

        //clober 종류 확인 (출입용 + 방향)
        List code2 = [manu[a]?[2], manu[a]?[3]];
        debugPrint("출입 확인 : ${code2.toString()}");
        if(listEquals(code2, [1, 1])) {
          debugPrint("ID Check : ${res.device.id}");
          debugPrint("Get List : ${cloberList[res.device.id.toString()]}");
          int sum = 0;
          List? tempList = cloberList[res.device.id.toString()];
          if (tempList != null) {
            for (int a in tempList) {
              sum += a;
            }
          }
          forwardRssi = sum~/tempList!.length;
          debugPrint("Input North");
          //정면
        } else if (listEquals(code2, [1, 3])) {
          debugPrint("ID Check : ${res.device.id}");
          debugPrint("Get List : ${cloberList[res.device.id.toString()]}");
          int sum = 0;
          List? tempList = cloberList[res.device.id.toString()];
          if (tempList != null) {
            for (int a in tempList) {
              sum += a;
            }
          }
          backRssi = sum~/tempList!.length;
          debugPrint("Input South");
          //후면
        } else {
          debugPrint("Not Input Pass");
          continue;
        }
        cid = "";
        bat = manu[a]![8].toString();
        List cidlist = [manu[a]?[4], manu[a]?[5], manu[a]?[6], manu[a]?[7]];

        //package에서 주는 값은 dec임 hex로 변환
        if (cidlist[0] < 16) {
          cid += "0";
        }
        cid += cidlist[0].toRadixString(16).toString();
        if (cidlist[1] < 16) {
          cid += "0";
        }
        cid += cidlist[1].toRadixString(16).toString();
        if (cidlist[2] < 16) {
          cid += "0";
        }
        cid += cidlist[2].toRadixString(16).toString();
        if (cidlist[3] < 16) {
          cid += "0";
        }
        cid += cidlist[3].toRadixString(16).toString();

        rssi = (forwardRssi + backRssi)/2;
        //스캔된 device 값 확인 (clober라면)
        debugPrint("==================");
        debugPrint("cid : $cid\nrssi : $rssi\nbat : $bat");
        debugPrint("==================");
        //RSSI 최대값 비교
        if ((rssi > maxRssi) && code2[0] == 1) {
          debugPrint("New Max");
          maxCid = cid;
          maxRssi = rssi;
          maxBat = bat;
          maxR = res;
          returnValue = Future.value(true);
        } else {
          debugPrint("Not Max");
        }
      } else {
        debugPrint("Pass");
        returnValue = Future.value(false);
      }
    }

    return returnValue ?? Future.value(false);
  }

  //maxCid 설정 여부로 clober 검색 여부 확인
  bool findClober() {
    if (maxCid == notFound) {
      return false;
    }
    return true;
  }

  //max 초기값
  void clearMax() {
    maxCid = notFound;
    //신호 세기 조절
    //-100이 신호 최소치 Android 소스코드 기준 옵션으로 -75 ~ -95 로 조절 가능
    maxRssi = -100;
    maxBat = notFound;
  }

  //BLE 연결
  Future<bool> connect() async {
    Future<bool>? returnValue;
    StreamSubscription<List<int>> valueStream;
    bool isFail = false;
    bool loading = true;
    //연결 시도 (ScanResult.device에서 .connect로 함)
    await maxR.device
        .connect(autoConnect: true)
    //시간제한 설정
        .timeout(const Duration(milliseconds: 2000), onTimeout: () {
          debugPrint('Fail BLE Connect');
          returnValue = Future.value(false);
          isFail = true;
    });
    if (isFail) {
      return returnValue ?? Future.value(false);
    }
    debugPrint('connect');
    returnValue = Future.value(true);

    //device 내 service 검색
    late List<BluetoothService> services;
    try {
      services = await maxR.device.discoverServices()
          .timeout(const Duration(milliseconds: 1500));
    } on TimeoutException catch (_) {
      debugPrint('Fail Service Search');
      returnValue = Future.value(false);
      isFail = true;
    }
    if (isFail) {
      return returnValue ?? Future.value(false);
    }

    //key값 가져오기용 manufacturerData 미리 가져오기 (19, 20byte에 key 값)
    Map<int, List<int>> readData = maxR.advertisementData.manufacturerData;
    //map의 key값 가져오기
    int a = readData.keys.toList().first;
    debugPrint("manu Check : ${readData[a]}");
    //출입용 Clober의 1번 안테나 저장용
    //1번 안테나 write용, 2번 안테나 read용
    late BluetoothCharacteristic char1;
    for (var service in services) {
      List<int> listenValue;
      var characteristics = service.characteristics;

      //Service UUID로 목표 Service 찾기
      List<String> temp = service.uuid.toString().split("-");
      debugPrint(temp[0]);
      //iOS 기준 Service UUID의 첫 부분만으로 serch하기에 일단 따라함
      //ex. 0000-1111-2222-3333이 UUID이면 -으로 나눠서 첫번째 0000
      //찾는 service의 UUID값 3559 (0채워서)
      if (temp[0] == "00003559") {
        debugPrint("목표 Service");
      } else {
        continue;
      }

      //Service 안에 목표인 Characteristic 찾기
      //구조 device -> service -> characteristic
      for (BluetoothCharacteristic c in characteristics) {
        debugPrint('Character 구조 : ${c.toString()}');
        debugPrint('Character UUID : ${c.uuid}');

        List<String> temp2 = c.uuid.toString().split("-");
        debugPrint(temp2[0]);
        //Service 때와 같이 Charateristic UUID로 목표 찾기
        //1은 wirte용 2는 read용
        if (temp2[0] == "00000002") {
          debugPrint("목표 Charateristic");
          debugPrint("Notifying Check : ${c.isNotifying}");
          debugPrint("Readable Check : ${c.properties.read}");
          debugPrint("Notify Check : ${c.properties.notify}");
          await c.setNotifyValue(true);
          //write 이후 characteristic의 response를 얻는 listener
          valueStream = c.onValueChangedStream.listen((value) async {
            loading = false;
            debugPrint('!!!!!Value Changed');
            listenValue = value;
            debugPrint('!!!!!Value check : $listenValue');
          });

          //연결은 이미 되어 있으므로 목표 Characteristic에 START라는 신호를 write해줌
          //START 신호 생성 (정확히는 cloberID 4자리 + START)
          debugPrint("Start Write 시작");
          List<int> start = [readData[a]![4], readData[a]![5], readData[a]![6], readData[a]![7], 0x53, 0x54, 0x41, 0x52, 0x54];
          //저장돼 있던 write용 Characteristic에 write 진행
          await char1.write(start, withoutResponse: true);
          while (loading) {
            debugPrint("Waiting Reponse...");
            await Future.delayed(const Duration(milliseconds: 1000));
          }
          loading = true;
          //위의 onValueChangedStream에서 Response를 읽어옴

          //Android식으로 Key값을 manufacturerData에서 읽어옴
          k1 = readData[a]![8];
          k2 = readData[a]![9];
          debugPrint('Key1 Check : ${readData[a]![8]}');
          debugPrint('Key2 Check : ${readData[a]![9]}');
          /*String httpResult;
          //전화 번호 필요 UserData 구축 전까진 주석처리
          httpResult = await http.evCall(cid, phoneNumber);*/
          debugPrint('Clober ID : $maxCid');

          debugPrint("Notifying Check : ${c.isNotifying}");

          debugPrint("암호화 시작");
          var finds2 = db.findCloberByCID(maxCid);
          enc = Encryption(finds2.userid, maxCid, finds2.pk, k1, k2);
          enc.init();
          enc.startEncryption();
          debugPrint("Encryption Write 시작");
          debugPrint("Encryption 확인 : ${enc.temp1}");
          debugPrint("Encryption 확인 : ${enc.temp2}");
          debugPrint("Encryption 확인 : ${enc.temp3}");
          debugPrint("Encryption 확인 : ${enc.temp4}");
          debugPrint("Encryption 확인 : ${enc.temp5}");
          debugPrint("Encryption 확인 : ${enc.result}");

          await char1.write(enc.result, withoutResponse: true);
          debugPrint('Read Value : ${c.lastValue}');
          while (loading) {
            debugPrint("Waiting Reponse...");
            await Future.delayed(const Duration(milliseconds: 1000));
          }
          debugPrint("암호화 성공 : ${!loading}");
          loading = true;
          /*debugPrint("Charac Read 시작");
          List<int> value = await c.read();
          debugPrint('Read Check (char) : $value');*/

          valueStream.cancel();
        } else {
          //1일 때는 write용이므로 일단 char1에 저장해두고 read용인 2찾으러가기
          debugPrint("Write Charateristic");
          char1 = c;
        }
      }
    }

    return returnValue ?? Future.value(false);
  }

  //connect된 BLE 끊기
  void disconnect() {
    debugPrint("Disconnecting...");
    maxR.device.disconnect();
  }

  //Android도 Connect하면서 안씀 일단 냅둠
  void writeBle() {
    debugPrint('write BLE');
  }
}