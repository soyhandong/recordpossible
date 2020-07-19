import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medcorder_audio/medcorder_audio.dart';
import 'package:permissions_plugin/permissions_plugin.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  MedcorderAudio audioModule = new MedcorderAudio();
  bool canRecord = false;
  double recordPower = 0.0;
  double recordPosition = 0.0;
  bool isRecord = false;
  bool isPlay = false;
  double playPosition = 0.0;
  String file = "";

  @override
  initState() {
    super.initState();
    audioModule.setCallBack((dynamic data) {
      _onEvent(data);
    });
    _initSettings();
  }

  Future _initSettings() async {
    final String result = await audioModule.checkMicrophonePermissions();
    if (result == 'OK') {
      await audioModule.setAudioSettings();
      setState(() {
        canRecord = true;
      });
    }
    return;
  }

  Future _startRecord() async {
    try {
      DateTime time = new DateTime.now();
      setState(() {
        file = time.millisecondsSinceEpoch.toString();
      });
      final String result = await audioModule.startRecord(file);
      setState(() {
        isRecord = true;
      });
      print('startRecord: ' + result);
    } catch (e) {
      file = "";
      print('startRecord: fail');
    }
  }

  Future _stopRecord() async {
    try {
      final String result = await audioModule.stopRecord();
      print('stopRecord: ' + result);
      setState(() {
        isRecord = false;
      });
    } catch (e) {
      print('stopRecord: fail');
      setState(() {
        isRecord = false;
      });
    }
  }

  Future _startStopPlay() async {
    if (isPlay) {
      await audioModule.stopPlay();
    } else {
      await audioModule.startPlay({
        "file": file,
        "position": 0.0,
      });
    }
  }

  void _onEvent(dynamic event) {
    if (event['code'] == 'recording') {
      double power = event['peakPowerForChannel'];
      setState(() {
        recordPower = (60.0 - power.abs().floor()).abs();
        recordPosition = event['currentTime'];
      });
    }
    if (event['code'] == 'playing') {
      String url = event['url'];
      setState(() {
        playPosition = event['currentTime'];
        isPlay = true;
      });
    }
    if (event['code'] == 'audioPlayerDidFinishPlaying') {
      setState(() {
        playPosition = 0.0;
        isPlay = false;
      });
    }
  }

  Future<void> checkPermissions(BuildContext context) async {

    final PermissionState aks = await PermissionsPlugin.isIgnoreBatteryOptimization;

    PermissionState resBattery;
    if(aks != PermissionState.GRANTED)
      resBattery = await PermissionsPlugin.requestIgnoreBatteryOptimization;

    print(resBattery);

    Map<Permission, PermissionState> permission = await PermissionsPlugin
        .checkPermissions([
      Permission.RECORD_AUDIO,
    ]);

    if( permission[Permission.RECORD_AUDIO] != PermissionState.GRANTED) {

      try {
        permission = await PermissionsPlugin
            .requestPermissions([
          Permission.RECORD_AUDIO,
        ]);
      } on Exception {
        debugPrint("Error");
      }

      if( permission[Permission.RECORD_AUDIO] == PermissionState.GRANTED )
        print("Login ok");
      else
        permissionsDenied(context);

    } else {
      print("Login ok");
    }
  }

  void permissionsDenied(BuildContext context){
    showDialog(context: context, builder: (BuildContext _context) {
      return SimpleDialog(
        title: const Text("Permisos denegados"),
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(left: 30, right: 30, top: 15, bottom: 15),
            child: const Text(
              "Debes conceder todo los permiso para poder usar esta aplicacion",
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54
              ),
            ),
          )
        ],
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    checkPermissions(context);
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Audio example app'),
        ),
        body: new Center(
          child: canRecord
              ? new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new InkWell(
                      child: new Container(
                        alignment: FractionalOffset.center,
                        child: new Text(isRecord ? 'Stop' : 'Record'),
                        height: 40.0,
                        width: 200.0,
                        color: Colors.blue,
                      ),
                      onTap: () {
                        if (isRecord) {
                          _stopRecord();
                        } else {
                          _startRecord();
                        }
                      },
                    ),
                    new Text('recording: ' + recordPosition.toString()),
                    new Text('power: ' + recordPower.toString()),
                    new InkWell(
                      child: new Container(
                        margin: new EdgeInsets.only(top: 40.0),
                        alignment: FractionalOffset.center,
                        child: new Text(isPlay ? 'Stop' : 'Play'),
                        height: 40.0,
                        width: 200.0,
                        color: Colors.blue,
                      ),
                      onTap: () {
                        if (!isRecord && file.length > 0) {
                          _startStopPlay();
                        }
                      },
                    ),
                    new Text('playing: ' + playPosition.toString()),
                  ],
                )
              : new Text(
                  'Microphone Access Disabled.\nYou can enable access in Settings',
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}
