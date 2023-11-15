import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:encrypt/encrypt.dart';
import 'package:flutter/cupertino.dart';

class AES256 {
  static final key = enc.Key.fromUtf8('123wifive_value_AES_hash45678901');
  static final Uint8List testV = Uint8List(16);
  static encryptAES(String text) {
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7'));
    final encrypted = encrypter.encrypt(text, iv: IV(testV));
    debugPrint("암호화1 : $encrypted");
    debugPrint("암호화2 : ${encrypted.base16}");
    debugPrint("암호화3 : ${encrypted.base64}");
    return encrypted.base16;

    // final key = enc.Key.fromUtf8(AESkey);
    // final iv = enc.IV.fromLength(16);
    //
    // final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    // final encrypted = encrypter.encrypt(text, iv: iv);
    //
    // print('Encrypted Text: ${encrypted.bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join()}');
    // return encrypted.bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  // static decryptAES(String encrypted) {
  //   final encrypter = encrypt.Encrypter(encrypt.AES(key));
  //   final decrypted = encrypter.decrypt64(encrypted, iv: iv);
  //   return decrypted;
  // }
}


