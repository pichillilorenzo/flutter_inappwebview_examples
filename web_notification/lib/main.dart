import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:vibration/vibration.dart';

import 'web_notification.dart';

final userScripts = <UserScript>[];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb &&
      kDebugMode &&
      defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  final jsNotificationApiUserScript = UserScript(
      source: await rootBundle.loadString('assets/web_notification.js'),
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START);
  userScripts.add(jsNotificationApiUserScript);

  await WebNotificationPermissionDb.loadSavedPermissions();

  final json = jsonEncode(WebNotificationPermissionDb.getPermissions());
  userScripts.add(UserScript(source: """
    (function(window) {
      var notificationPermissionDb = $json;
      if (notificationPermissionDb[window.location.host] === 'granted') {
        Notification._permission = 'granted';
      } 
    })(window);
    """, injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START));

  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  WebNotificationController? webNotificationController;

  void handleClick(int item) async {
    switch (item) {
      case 0:
        await webNotificationController?.requestPermission();
        break;
      case 1:
        await webViewController?.evaluateJavascript(source: """
          var testNotification = new Notification('Notification Title', {body: 'Notification Body!', icon: 'https://picsum.photos/150?random=' + Date.now(), vibrate: [200, 100, 200]});
          testNotification.addEventListener('show', function(event) {
            console.log('show log');
          });
          testNotification.addEventListener('click', function(event) {
            console.log('click log');
          });
          testNotification.addEventListener('close', function(event) {
            console.log('close log');
          });
        """);
        break;
      case 2:
        await webViewController?.evaluateJavascript(source: """
          try {
            if (testNotification != null) {
              testNotification.close();
            }
          } catch {}
        """);
        break;
      case 3:
        WebNotificationPermissionDb.clear();
        await webNotificationController?.resetPermission();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Web Notification"),
          actions: [
            PopupMenuButton<int>(
              onSelected: (item) => handleClick(item),
              itemBuilder: (context) => [
                const PopupMenuItem<int>(
                    value: 0, child: Text('Request Notification Permission')),
                const PopupMenuItem<int>(
                    value: 1, child: Text('Create Notification')),
                const PopupMenuItem<int>(
                    value: 2, child: Text('Close Notification')),
                const PopupMenuItem<int>(
                    value: 3, child: Text('Reset Notification Permissions')),
              ],
            ),
          ],
        ),
        body: Column(children: <Widget>[
          Expanded(
            child: InAppWebView(
              key: webViewKey,
              initialUrlRequest:
                  URLRequest(url: WebUri("https://github.com/flutter")),
              initialUserScripts: UnmodifiableListView(userScripts),
              onWebViewCreated: (controller) {
                webViewController = controller;
                webNotificationController =
                    WebNotificationController(controller);
                addJavaScriptHandlers();
              },
            ),
          ),
        ]));
  }

  void addJavaScriptHandlers() {
    webViewController?.addJavaScriptHandler(
      handlerName: 'Notification.requestPermission',
      callback: (arguments) async {
        final permission = await onNotificationRequestPermission();
        return permission.name.toLowerCase();
      },
    );

    webViewController?.addJavaScriptHandler(
      handlerName: 'Notification.show',
      callback: (arguments) {
        if (webViewController != null) {
          final notification =
              WebNotification.fromJson(arguments[0], webViewController!);
          onShowNotification(notification);
        }
      },
    );

    webViewController?.addJavaScriptHandler(
      handlerName: 'Notification.close',
      callback: (arguments) {
        final notificationId = arguments[0];
        onCloseNotification(notificationId);
      },
    );
  }

  Future<WebNotificationPermission> onNotificationRequestPermission() async {
    final url = await webViewController?.getUrl();

    if (url != null) {
      final savedPermission =
          WebNotificationPermissionDb.getPermission(url.host);
      if (savedPermission != null) {
        return savedPermission;
      }
    }

    final permission = await showDialog<WebNotificationPermission>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('${url?.host} wants to show notifications'),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop<WebNotificationPermission>(
                          context, WebNotificationPermission.DENIED);
                    },
                    child: const Text('Deny')),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop<WebNotificationPermission>(
                          context, WebNotificationPermission.GRANTED);
                    },
                    child: const Text('Grant'))
              ],
            );
          },
        ) ??
        WebNotificationPermission.DENIED;

    if (url != null) {
      await WebNotificationPermissionDb.savePermission(url.host, permission);
    }

    return permission;
  }

  void onShowNotification(WebNotification notification) async {
    webNotificationController?.notifications[notification.id] = notification;

    var iconUrl =
        notification.icon != null ? Uri.tryParse(notification.icon!) : null;
    if (iconUrl != null && !iconUrl.hasScheme) {
      iconUrl = Uri.tryParse(
          (await webViewController?.getUrl()).toString() + iconUrl.toString());
    }

    final snackBar = SnackBar(
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Action',
        onPressed: () async {
          await notification.dispatchClick();
        },
      ),
      content: Row(
        children: <Widget>[
          iconUrl != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Image.network(
                    iconUrl.toString(),
                    width: 50,
                  ),
                )
              : Container(),
          // add your preferred text content here
          Expanded(
              child: Text(
                  notification.title +
                      (notification.body != null
                          ? '\n${notification.body!}'
                          : ''),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    notification.snackBarController =
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
    notification.snackBarController?.closed.then((value) async {
      notification.snackBarController = null;
      await notification.close();
    });

    final vibrate = notification.vibrate;
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator && vibrate != null && vibrate.isNotEmpty) {
      if (vibrate.length % 2 != 0) {
        vibrate.add(0);
      }
      final intensities = <int>[];
      for (int i = 0; i < vibrate.length; i++) {
        if (i % 2 == 0 && vibrate[i] > 0) {
          intensities.add(255);
        } else {
          intensities.add(0);
        }
      }
      await Vibration.vibrate(pattern: vibrate, intensities: intensities);
    }
  }

  void onCloseNotification(int id) {
    final notification = webNotificationController?.notifications[id];
    if (notification != null) {
      final snackBarController = notification.snackBarController;
      if (snackBarController != null) {
        snackBarController.close();
      }
      webNotificationController?.notifications.remove(id);
    }
  }
}
