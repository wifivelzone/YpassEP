import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleScanService {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  List<ScanResult> scanResultList = [];
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
    flutterBlue.isScanning.listen((isScanning) {
      _isScanning = isScanning;
    });
  }

  Future<void> scan() async {
    if (!_isScanning) {
      scanResultList.clear();
      flutterBlue.startScan(scanMode: ScanMode.balanced ,withServices: [Guid("00003559-0000-1000-8000-00805F9B34FB")], timeout: const Duration(seconds: 4));
      flutterBlue.scanResults.listen((results) {
        scanResultList = results;
      });
    } else {
      flutterBlue.stopScan();
    }
  }

  Future<void> searchClober() async {
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
        }
      }
    }
  }

  bool findClober() {
    if (maxCid == notFound) {
      return false;
    }
    return true;
  }

  void clearMax() {
    maxCid = 'none';
    maxRssi = -79.9;
    maxBat = 'none';
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
    debugPrint("service data 체크: ${maxR.advertisementData.serviceData.toString()}");
    debugPrint("services 구조: ${services.toString()}");
    for (var service in services) {
      var characteristics = service.characteristics;
      debugPrint("characteristics 구조: ${characteristics.toString()}");
      for (BluetoothCharacteristic c in characteristics) {
        List<int> value = await c.read();
        debugPrint('$value');

        if (c.uuid == Guid('')) {
          debugPrint('Find it!');
          //List<int> start = [0x1, 0x1, 0x1, 0x3, 0x53, 0x54, 0x41, 0x52, 0x54];
          //await c.write(start);
        }
      }
    }

    return returnValue ?? Future.value(false);
  }

  void writeBle() {
    debugPrint('write BLE');
  }
}