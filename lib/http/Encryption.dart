import 'dart:convert';
import 'dart:typed_data';

class Encryption {
  String userid;
  String cid;
  String pk;
  int k1;
  int k2;

  late List listUserid;
  late List listCID;
  late String modK1;
  late String modK2;

  late String temp1;
  late String temp2;
  late String temp3;
  late String temp4;
  late String temp5;

  late int check;

  late List<int> result;

  List digits = [
  '0', '1', '2', '3', '4', '5',
  '6', '7', '8', '9',
  'a', 'b', 'c', 'd', 'e', 'f',
  'g', 'h', 'i', 'j', 'k', 'l',
  'm', 'n', 'o', 'p', 'q', 'r',
  's', 't', 'u', 'v', 'w', 'x',
  'y', 'z',
  'A', 'B', 'C', 'D', 'E', 'F',
  'G', 'H', 'I', 'J', 'K', 'L',
  'M', 'N', 'O', 'P', 'Q', 'R',
  'S', 'T', 'U', 'V', 'W', 'X',
  'Y', 'Z'
  ];

  Encryption(this.userid, this.cid, this.pk, this.k1, this.k2);

  void init() {
    listUserid = [userid.substring(0,2), userid.substring(2,4), userid.substring(4,6), userid.substring(6,8), userid.substring(8,10), userid.substring(10,12)];
    listCID = [cid.substring(0,2), cid.substring(2,4), cid.substring(4,6), cid.substring(6,8)];
    modK1 = (k1 % 10).toString();
    modK2 = (k2 % 10).toString();
  }

  void startEncryption() {
    temp1 = listUserid[0]+listUserid[1]+modK1.codeUnitAt(0).toString()+listUserid[2];
    temp2 = listUserid[3]+modK2.codeUnitAt(0).toString()+listUserid[4]+listUserid[5];

    temp3 = convert62(temp1);
    temp4 = convert62(temp2);

    temp5 = temp3+temp4;
    check = temp5.length;
    if (temp5.length < 12) {
      for (int i = 0; i < 12-check; i++) {
        if (i % 2 == 0) {
          temp5 = temp5 + pk[int.parse(modK2)];
        } else {
          temp5 = pk[int.parse(modK1)] + temp5;
        }
      }
    }

    List<int> list = ascii.encode(temp5);
    //List convetedList = list.map((number) => number.toRadixString(16)).toList();
    result = [list[0], int.parse(listUserid[0]), list[1], list[2], k1, int.parse(listUserid[1]), list[3], list[4], int.parse(listUserid[2]), list[5], list[6], int.parse(listUserid[3]), list[7], list[8], int.parse(listUserid[4]), k2, list[9], list[10], int.parse(listUserid[5]), list[11]];
    //result = list;
    //resTest = idList;
  }

  String convert62(String num) {
    int inputNum = int.parse(num);
    String result = "";
    int radix = digits.length;


    while (inputNum > 0) {
      int quotient = inputNum ~/ radix;
      int mod = inputNum % radix;

      inputNum = quotient;
      result = digits[mod] + result;
    }

    return result;
  }
}