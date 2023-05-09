import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleScanService {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  List<ScanResult> scanResultList = [];
  late StreamSubscription subscription;
  List cloberList = [];
  bool _isScanning = false;

  late String cid;
  late num rssi;
  late String bat;

  late String maxCid;
  late num maxRssi;
  late String maxBat;
  late ScanResult maxR;

  final String notFound = "none";

  initBle() {
    subscription = flutterBlue.isScanning.listen((isScanning) {
      _isScanning = isScanning;
    });
  }

  disposeBle() {
    subscription.cancel();
  }

  Future<bool> scan() async {
    Future<bool>? returnValue;
    if (!_isScanning) {
      scanResultList.clear();
      flutterBlue.startScan(
          scanMode: ScanMode.lowLatency,
          allowDuplicates: true,
          withServices: [Guid("00003559-0000-1000-8000-00805F9B34FB")],
          timeout: const Duration(seconds: 4)
      );
      flutterBlue.scanResults.listen((results) {
        scanResultList = results;
      });
      returnValue = Future.value(true);
    } else {
      flutterBlue.stopScan();
      returnValue = Future.value(false);
    }

    return returnValue;
  }

  void stopScan() {
    flutterBlue.stopScan();
  }

  Future<bool> searchClober() async {
    Future<bool>? returnValue;
    clearMax();
    for (ScanResult res in scanResultList) {
      var manu = res.advertisementData.manufacturerData;

      if(manu.keys.toList().isNotEmpty){
        int a = manu.keys.toList().first;
        List code = [manu[a]?[0], manu[a]?[1]];
        List coop = [76, 90];

        if(listEquals(code, coop) && a == 13657){
          debugPrint("yes Clober");
        } else {
          debugPrint("no Clober");
          returnValue = Future.value(false);
        }

        List code2 = [manu[a]?[2], manu[a]?[3]];
        if(listEquals(code2, [1, 1])) {
          debugPrint("Input North");
          //정면
        } else if (listEquals(code2, [1, 2])) {
          debugPrint("Input South");
          //후면
        }
        cid = "";
        rssi = res.rssi;
        bat = manu[a]![8].toString();
        List cidlist = [manu[a]?[4], manu[a]?[5], manu[a]?[6], manu[a]?[7]];

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

        debugPrint("==================");
        debugPrint("cid : $cid\nrssi : $rssi\nbat : $bat");
        debugPrint("==================");
        if (rssi > maxRssi) {
          maxCid = cid;
          maxRssi = rssi;
          maxBat = bat;
          maxR = res;
          returnValue = Future.value(true);
        }
      } else {
        returnValue = Future.value(false);
      }
    }

    return returnValue ?? Future.value(false);
  }

  bool findClober() {
    if (maxCid == notFound) {
      return false;
    }
    return true;
  }

  void clearMax() {
    maxCid = notFound;
    maxRssi = -79.9;
    maxBat = notFound;
  }

  Future<bool> connect() async {
    Future<bool>? returnValue;
    await maxR.device
        .connect(autoConnect: false)
        .timeout(const Duration(milliseconds: 2000), onTimeout: () {
          debugPrint('Fail BLE Connect');
          returnValue = Future.value(false);
    });
    debugPrint('connect');
    returnValue = Future.value(true);

    List<BluetoothService> services = await maxR.device.discoverServices();
    Map<int, List<int>> readData = maxR.advertisementData.manufacturerData;
    int a = readData.keys.toList().first;
    late BluetoothCharacteristic char1;
    for (var service in services) {
      var characteristics = service.characteristics;

      List<String> temp = service.uuid.toString().split("-");
      debugPrint(temp[0]);
      if (temp[0] == "00003559") {
        debugPrint("목표 Service");;
      } else {
        continue;
      }

      for (BluetoothCharacteristic c in characteristics) {
        debugPrint('Character 구조 : ${c.toString()}');
        debugPrint('Character UUID : ${c.uuid}');

        List<String> temp2 = c.uuid.toString().split("-");
        debugPrint(temp2[0]);
        if (temp2[0] == "00000002") {
          debugPrint("목표 Charateristic");
          List<int> start = [0x1, 0x1, 0x1, 0x3, 0x53, 0x54, 0x41, 0x52, 0x54];
          await char1.write(start, withoutResponse: true);
          debugPrint('Read Check : ${readData[a]}');
          debugPrint('Key1 Check : ${readData[a]![8]}');
          debugPrint('Key2 Check : ${readData[a]![9]}');
        } else {
          debugPrint("Write Charateristic");
          char1 = c;
        }
      }
    }

    return returnValue ?? Future.value(false);
  }

  void disconnect() {
    maxR.device.disconnect();
  }

  void writeBle() {
    debugPrint('write BLE');
  }
}