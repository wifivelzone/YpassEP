import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:ypass/http/HttpPostData.dart' as http;
import 'package:ypass/http/Encryption.dart';
import 'package:ypass/realm/SettingDBUtil.dart';
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
  Map<String, List> outCloberList = {};
  Map<String, List> skippedCloberList = {};

  //지금 스캔 중인가?
  bool _isScanning = false;
  bool timerValid = false;
  bool scanRestart = true;
  bool scanDone = false;
  bool searchDone = false;
  bool connecting = false;

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

  //Clober Key
  late int k1;
  late int k2;

  //경산용 Ev 처리
  bool isEv = false;
  //초기값 2000년 1월 1일 0시 0분 0초
  DateTime lastEv = DateTime(2000);

  final String notFound = "none";
  late Encryption enc;
  UserDBUtil db = UserDBUtil();

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
    scanResultList.clear();
    cloberList.clear();
    int counter = 0;
    Future<bool>? returnValue;
    DateTime scanTime = DateTime.now();
    //이미 스캔 중인지 확인
    debugPrint("Is Scanning? : $_isScanning");
    if (!_isScanning) {
      scanRestart = false;
      Future.delayed(const Duration(seconds: 1), (){
        debugPrint("1 Second !!!");
        timerValid = true;
      });
      Timer duration = Timer.periodic(const Duration(milliseconds: 100), (timer) {
         if (timerValid && counter > 15) {
        //if (timerValid && counter > 0) {
          DateTime nowTime = DateTime.now();
          debugPrint("Not Time or Not 15 Count");
          if (nowTime.millisecondsSinceEpoch-scanTime.millisecondsSinceEpoch > 1000) {
            debugPrint("Scan Cut !!!");
            counter = 0;
            timerValid = false;
            scanDone = true;
            scanTime = nowTime;
          }
        }
      });
      //기존 scan list 초기화
      scanResultList.clear();
      cloberList.clear();
      //스캔 시작
      flutterBlue.startScan(
          //성능 설정
          scanMode: ScanMode.lowLatency,
          //중복 scan 가능 설정
          allowDuplicates: true,
          //UUID filter 설정
          withServices: [Guid("00003559-0000-1000-8000-00805F9B34FB")],
          //시간초 설정 (4초)
          timeout: const Duration(seconds: 15)
      ).then((_) {
        duration.cancel();
        scanRestart = true;
        stopListen();
      });
      //스캔 결과 (list형태)가 나오면 가져와서 저장
      resStream = flutterBlue.scanResults.listen((results) {
        counter++;
        scanResultList = results;
        debugPrint("Scan Counter : $counter");
        debugPrint("Scan Length : ${scanResultList.length}");
        for(ScanResult res in scanResultList) {
          if (cloberList[res.device.id.toString()] == null) {
            cloberList.addEntries({"${res.device.id}" : [res.rssi]}.entries);
          } else {
            if (cloberList[res.device.id.toString()]!.length >= 30) {
              cloberList[res.device.id.toString()]?.removeAt(0);
            }
            cloberList[res.device.id.toString()]?.add(res.rssi);
          }
        }
        //searchClober();
      });
      returnValue = Future.value(true);
    } else {
      //이미 작동 중이었으면 넘어감
      debugPrint("Scanning...");
      returnValue = Future.value(false);
    }

    return returnValue;
  }

  //스캔 중단
  void stopScan() {
    flutterBlue.stopScan();
    resStream.cancel();
  }
  void stopListen() {
    resStream.cancel();
  }

  //scan 결과 중에 clober 찾기
  Future<bool> searchClober() async {
    debugPrint("Start Search!!");
    Future<bool>? returnValue;
    isEv = false;
    int forwardRssi = -100;
    int backRssi = -100;
    //기존 RSSI MAX 값들 초기화
    clearMax();
    List<ScanResult> scanResultListCopy = List.from(scanResultList);
    debugPrint("Length Check : ${scanResultList.length}");
    Map<String, List> cloberListCopy = Map.from(cloberList);
    outCloberList.clear();
    skippedCloberList.clear();

    for (int i = 0; i < scanResultListCopy.length; i++) {
      ScanResult res = scanResultListCopy[i];
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
          debugPrint("==================");
          continue;
        }

        //clober 종류 확인 (출입용 + 방향)
        List code2 = [manu[a]?[2], manu[a]?[3]];
        debugPrint("출입 확인 : ${code2.toString()}");
        if(listEquals(code2, [1, 1])) {
          if (manu[a]?[8] == 0 && manu[a]?[9] == 0) {
            debugPrint("invalid Clober");
            continue;
          }
          //정면 Clober는 RSSI 평균 계산 후 후면 Clober RSSI 평균이 있으면 진행, 아니면 ScanResultList마지막에 다시 추가하고 continue
          //이미 후면 Clober RSSI가 있는 정면 Clober만 진행시킴으로 Clober가 여러개여도 구분 가능
          debugPrint("ID Check : ${res.device.id}");
          debugPrint("Get List : ${cloberListCopy[res.device.id.toString()]}");
          int sum = 0;
          List? tempList = cloberListCopy[res.device.id.toString()];
          debugPrint("Length Check : ${tempList?.length}");
          if (tempList != null) {
            for (int a in tempList) {
              sum += a;
            }
          }
          //쿨타임 3분으로 (계속 눌리면 EV문이 계속 열리니)
          if (DateTime.now().millisecondsSinceEpoch - lastEv.millisecondsSinceEpoch < 3*60*1000){
            debugPrint("But Cooldown ... (3 minute)");
            continue;
          }

          //후면 Clober RSSI가 저장되어 있는지 확인
          if (outCloberList["${manu[a]![4]}.${manu[a]![5]}.${manu[a]![6]}.${manu[a]![7]}"] == null) {
            debugPrint("Before Input South!!");
            debugPrint("==================");
            //두번 skip은 짝인 1.3 Clober가 없다고 판단 pass
            if (skippedCloberList["${manu[a]![4]}.${manu[a]![5]}.${manu[a]![6]}.${manu[a]![7]}"] != null) {
              debugPrint("Arleady Skipped Clober!!");
              debugPrint("==================");
              continue;
            }
            //단 경산용 EV Clober는 따로 처리 (정면 밖에 없음)
            //Clober ID로 EV용 구별
            if (manu[a]![6] == 2 && manu[a]![7] > 25 && manu[a]![7] < 45) {
              debugPrint("But EvClober");
              //유저 설정 확인
              SettingDataUtil setdb = SettingDataUtil();
              bool auto = setdb.getAutoFlowSelectState();

              //유저가 거부 해놨으면 pass
              if (auto) {
                //후면 RSSI도 있다고 치고 정면이랑 같은 값 넣어줌
                //EV Clober가 가장 가까이 있으면 결국 이게 MAX RSSI가 될 것
                forwardRssi = sum ~/ tempList!.length;
                backRssi = forwardRssi;
                isEv = true;
              } else {
                continue;
              }
            } else {
              //없으면 지금의 Clober를 list 맨 뒤로 보내고 continue (후면 인식되면 정면 되게)
              scanResultListCopy.add(res);
              skippedCloberList.addEntries({"${manu[a]![4]}.${manu[a]![5]}.${manu[a]![6]}.${manu[a]![7]}" : [backRssi]}.entries);
              continue;
            }
          } else {
            //후면 RSSI 평균이 있으면 읽어와서 back에 넣어줌 forward는 계산
            forwardRssi = sum~/tempList!.length;
            backRssi = outCloberList["${manu[a]![4]}.${manu[a]![5]}.${manu[a]![6]}.${manu[a]![7]}"]?.first;
            debugPrint("Input North");
            debugPrint("Fore : $forwardRssi, Back : $backRssi");
          }
          //정면
        } else if (listEquals(code2, [1, 3])) {
          //후면 Clober는 RSSI 평균 값만 저장하고 continue
          //outCloberList에 Clober ID를 key값으로 RSSI 평균을 저장함(정면, 후면 Clober ID가 같음)
          debugPrint("ID Check : ${res.device.id}");
          debugPrint("Get List : ${cloberListCopy[res.device.id.toString()]}");
          int sum = 0;
          List? tempList = cloberListCopy[res.device.id.toString()];
          if (tempList != null) {
            for (int a in tempList) {
              sum += a;
            }
          }
          backRssi = sum~/tempList!.length;
          debugPrint("Input South");
          outCloberList.addEntries({"${manu[a]![4]}.${manu[a]![5]}.${manu[a]![6]}.${manu[a]![7]}" : [backRssi]}.entries);
          debugPrint("==================");
          continue;
          //후면
        } else {
          //출입용 아니면 그냥 pass
          debugPrint("Not Input Pass");
          debugPrint("==================");
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
        //우선 isEv를 읽어 이게 EV용 Clober인지 확인
        if (isEv && rssi > maxRssi && rssi > -75.5 - SettingDataUtil().getUserSetRange()) {
          debugPrint("New Max with Ev");
          maxCid = cid;
          maxRssi = rssi;
          maxBat = bat;
          maxR = res;
          returnValue = Future.value(true);
        } else if ((rssi > maxRssi) && code2[0] == 1 && rssi > -75.5 - SettingDataUtil().getUserSetRange()) {
          //EV용 Clober가 이미 인식되어 있더라도
          //다른 Clober가 max 갱신되면 isEv = false
          debugPrint("New Max");
          maxCid = cid;
          maxRssi = rssi;
          maxBat = bat;
          maxR = res;
          isEv = false;
          returnValue = Future.value(true);
        } else {
          debugPrint("Not Max");
        }
        searchDone = true;
      } else {
        debugPrint("Pass");
        returnValue = Future.value(false);
      }
    }

    scanDone = false;
    debugPrint("Search Done? : $searchDone");
    try {
      var temp = db.findCloberByCID(maxCid);
      debugPrint(temp.cloberid);
    } catch (e) {
      debugPrint("접근할 수 없는 Clober 입니다.");
      searchDone = false;
    }
    if (!searchDone) {
      timerValid = true;
    }
    return returnValue ?? Future.value(false);
  }

  Future<bool> callEvGyeongSan() async {
    //경산 EvCall한 시간 갱신
    lastEv = DateTime.now();
    //전화 번호
    db.getDB();
    String phoneNumber = db.getUser().phoneNumber;
    //호수
    String ho = db.getDong()[1];
    //통신 (밖에서 부르는 것이므로 isInward false로)
    String result;
    result = await http.evCallGyeongSan(phoneNumber, false, maxCid, ho);
    debugPrint("통신 결과 : $result");
    if (result == "통신error") {
      return false;
    } else {
      return true;
    }
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
    searchDone = false;
    connecting = true;
    bool isFail = false;
    bool loading = true;
    bool callev = false;
    bool startSuccess = false;
    //연결 시도 (ScanResult.device에서 .connect로 함)
    await maxR.device
        .connect(autoConnect: false)
    //시간제한 설정
        .timeout(const Duration(milliseconds: 2000), onTimeout: () {
          debugPrint('Fail BLE Connect');
          returnValue = Future.value(false);
          isFail = true;
    });
    if (isFail) {
      connecting = false;
      timerValid = true;
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
      connecting = false;
      timerValid = true;
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
            //loading은 바로 해제
            loading = false;
            debugPrint('!!!!!Value Changed');
            listenValue = value;
            debugPrint('!!!!!Value check : $listenValue');
            //write 실패시 []가 읽혀옴
            //startSuccess 값으로 순서 구분
            if (listenValue.isEmpty && !startSuccess) {
              debugPrint("StartWrite 실패");
            } else if (!startSuccess){
              startSuccess = true;
              debugPrint("StartWrite 성공");
              //startSuccess가 true이면 암호화 단계로 인식
              //암호화 성공시 [80]이 읽힘
            } else if (listenValue.first == 80) {
              //EV 불러오는 것을 허가
              callev = true;
              debugPrint("암호화 성공 : $callev");
            } else {
              debugPrint("암호화 실패");
            }
          });

          //연결은 이미 되어 있으므로 목표 Characteristic에 START라는 신호를 write해줌
          //START 신호 생성 (정확히는 cloberID 4자리 + START)
          debugPrint("Start Write 시작");
          List<int> start = [readData[a]![4], readData[a]![5], readData[a]![6], readData[a]![7], 0x53, 0x54, 0x41, 0x52, 0x54];
          //저장돼 있던 write용 Characteristic에 write 진행
          await char1.write(start, withoutResponse: true);
          while (loading) {
            debugPrint("Waiting Reponse...");
            await Future.delayed(const Duration(milliseconds: 100));
          }
          if (!startSuccess) {
            valueStream.cancel();
            debugPrint("Start Write를 실패했습니다.");
            connecting = false;
            timerValid = true;
            return Future.value(false);
          }
          loading = true;
          //위의 onValueChangedStream에서 Response를 읽어옴

          //Android식으로 Key값을 manufacturerData에서 읽어옴
          k1 = readData[a]![8];
          k2 = readData[a]![9];
          debugPrint('Key1 Check : ${readData[a]![8]}');
          debugPrint('Key2 Check : ${readData[a]![9]}');
          debugPrint('Clober ID : $maxCid');

          debugPrint("Notifying Check : ${c.isNotifying}");

          //암호화 시작 부분
          debugPrint("암호화 시작");
          var finds2 = db.findCloberByCID(maxCid);
          enc = Encryption(finds2.userid, maxCid, finds2.pk, k1, k2);
          enc.init();
          enc.startEncryption();
          debugPrint("Encryption Write 시작");
          debugPrint("Encryption 확인 : ${enc.result}");

          await char1.write(enc.result, withoutResponse: true);
          debugPrint('Read Value : ${c.lastValue}');
          while (loading) {
            debugPrint("Waiting Reponse...");
            await Future.delayed(const Duration(milliseconds: 100));
          }
          loading = true;

          //암호화 성공했으면 EV Call 실행
          if (callev) {
            /*String result;
            result = await http.cloberPass(1, cid, maxRssi.toString());
            debugPrint("통신 결과 : $result");
            //전화 번호
            db.getDB();
            String phoneNumber = db.getUser().phoneNumber;
            String httpResult;

            httpResult = await http.evCall(maxCid, phoneNumber);
            debugPrint("통신 결과 : $httpResult");
            //최신 lastInCloberID 갱신
            SettingDataUtil set = SettingDataUtil();
            set.setLastInCloberID(maxCid);*/

            lastEv = DateTime.now();
          } else {
            valueStream.cancel();
            debugPrint("암호화를 실패했습니다.");
            connecting = false;
            timerValid = true;
            return Future.value(false);
          }
          valueStream.cancel();
        } else {
          //1일 때는 write용이므로 일단 char1에 저장해두고 read용인 2찾으러가기
          debugPrint("Write Charateristic");
          char1 = c;
        }
      }
    }

    connecting = false;
    timerValid = true;
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