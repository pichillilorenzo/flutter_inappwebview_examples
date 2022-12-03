import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb &&
      kDebugMode &&
      defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("WebRTC example"),
          actions: [
            TextButton(
                onPressed: () async {
                  await webViewController?.loadUrl(
                      urlRequest: URLRequest(
                          url: WebUri("https://apprtc.webrtcserver.cn/")));
                },
                child: const Text(
                  "AppRTC",
                  style: TextStyle(color: Colors.white),
                )),
            TextButton(
                onPressed: () async {
                  await webViewController?.loadUrl(
                      urlRequest: URLRequest(
                          url: WebUri(
                              "https://www.pubnub.com/developers/demos/webrtc/launch/")));
                },
                child: const Text("PubNub WebRTC",
                    style: TextStyle(color: Colors.white)))
          ],
        ),
        body: Column(children: <Widget>[
          Expanded(
            child: InAppWebView(
              key: webViewKey,
              initialUrlRequest:
                  URLRequest(url: WebUri("https://apprtc.webrtcserver.cn/")),
              initialSettings: InAppWebViewSettings(
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onPermissionRequest: (controller, request) async {
                final resources = <PermissionResourceType>[];
                if (request.resources.contains(PermissionResourceType.CAMERA)) {
                  final cameraStatus = await Permission.camera.request();
                  if (!cameraStatus.isDenied) {
                    resources.add(PermissionResourceType.CAMERA);
                  }
                }
                if (request.resources
                    .contains(PermissionResourceType.MICROPHONE)) {
                  final microphoneStatus =
                      await Permission.microphone.request();
                  if (!microphoneStatus.isDenied) {
                    resources.add(PermissionResourceType.MICROPHONE);
                  }
                }
                // only for iOS and macOS
                if (request.resources
                    .contains(PermissionResourceType.CAMERA_AND_MICROPHONE)) {
                  final cameraStatus = await Permission.camera.request();
                  final microphoneStatus =
                      await Permission.microphone.request();
                  if (!cameraStatus.isDenied && !microphoneStatus.isDenied) {
                    resources.add(PermissionResourceType.CAMERA_AND_MICROPHONE);
                  }
                }

                return PermissionResponse(
                    resources: resources,
                    action: resources.isEmpty
                        ? PermissionResponseAction.DENY
                        : PermissionResponseAction.GRANT);
              },
            ),
          ),
        ]));
  }
}
