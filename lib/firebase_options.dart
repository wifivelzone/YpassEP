// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBkoYzWCwZ0vNTsC284DWwUZIq6DntK92E',
    appId: '1:692410132364:web:cd5942cf9c07449d77d8a9',
    messagingSenderId: '692410132364',
    projectId: 'ypassflutter',
    authDomain: 'ypassflutter.firebaseapp.com',
    storageBucket: 'ypassflutter.appspot.com',
    measurementId: 'G-04Q5P3VJJR',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBpR0islAQh9jPUfy5yqoY2SuRnTC0N6_c',
    appId: '1:692410132364:android:697878729b04d9b177d8a9',
    messagingSenderId: '692410132364',
    projectId: 'ypassflutter',
    storageBucket: 'ypassflutter.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCa5g5ekgSLBVo5bN16Vhi7U1x44H1pjDA',
    appId: '1:692410132364:ios:8b676691aa74e31577d8a9',
    messagingSenderId: '692410132364',
    projectId: 'ypassflutter',
    storageBucket: 'ypassflutter.appspot.com',
    androidClientId: '692410132364-5t67irdbb4acv834pa4fv3n2mgouttg7.apps.googleusercontent.com',
    iosClientId: '692410132364-vjucu0ldem20s2h63jk6hbb3r5pm6gro.apps.googleusercontent.com',
    iosBundleId: 'com.wifive.inoutappgwanjeo',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCa5g5ekgSLBVo5bN16Vhi7U1x44H1pjDA',
    appId: '1:692410132364:ios:4363f13d2a1acc8677d8a9',
    messagingSenderId: '692410132364',
    projectId: 'ypassflutter',
    storageBucket: 'ypassflutter.appspot.com',
    androidClientId: '692410132364-5t67irdbb4acv834pa4fv3n2mgouttg7.apps.googleusercontent.com',
    iosClientId: '692410132364-t0latesfobl00b8e06u0hk23lev1ssvi.apps.googleusercontent.com',
    iosBundleId: 'com.example.ypass',
  );
}
