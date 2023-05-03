import 'package:flutter/material.dart';
import 'package:ypass/constant/color.dart';
import 'package:ypass/screen/serve/Bar.dart';

import 'MainScreen.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MAIN_BACKGROUND_COLOR,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Bar(barSize: 10.0),
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.2,
              child: Image.asset('asset/img/wifive.png'),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.2,
              child: Image.asset('asset/img/y5logo.png'),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext contex) => MainScreen(),
                  ),
                );
              },
              icon: Icon(Icons.ac_unit),
            ),

            Bar(barSize: 10.0),
          ],
        ),
      ),
    );
  }
}
