import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> isNetworkAvailable() async {
  // check if there is a valid network connection
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult != ConnectivityResult.mobile &&
      connectivityResult != ConnectivityResult.wifi) {
    return false;
  }

  // check if the network is really connected to Internet
  try {
    final result = await InternetAddress.lookup('example.com');
    if (result.isEmpty || result[0].rawAddress.isEmpty) {
      return false;
    }
  } on SocketException catch (_) {
    return false;
  }

  return true;
}

Future<bool> isPWAInstalled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isInstalled') ?? false;
}

void setPWAInstalled({bool installed = true}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isInstalled', installed);
}