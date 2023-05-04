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

  initBle() {
    flutterBlue.isScanning.listen((isScanning) {
      _isScanning = isScanning;
    });
  }

  Future<void> scan() async {
    if (!_isScanning) {
      scanResultList.clear();
      flutterBlue.startScan(withServices: [Guid("00003559-0000-1000-8000-00805F9B34FB")], timeout: const Duration(seconds: 4));
      flutterBlue.scanResults.listen((results) {
        scanResultList = results;
      });
    } else {
      flutterBlue.stopScan();
    }
  }

  Future<void> searchClober() async {
    //userdata.maxRssi = -100;
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
        /*if (rssi > userdata.maxRssi) {
          userdata.maxRssi = rssi;
          userdata.maxCid = cid;
          userdata.maxBat = bat;
        }*/
      }

    }

  }
}