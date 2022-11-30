import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const kInitialTextSize = 100;
const kTextSizePlaceholder = 'TEXT_SIZE_PLACEHOLDER';
const kTextSizeSourceJS = """
window.addEventListener('DOMContentLoaded', function(event) {
  document.body.style.textSizeAdjust = '$kTextSizePlaceholder%';
  document.body.style.webkitTextSizeAdjust = '$kTextSizePlaceholder%';
});
""";

final textSizeUserScript = UserScript(
    source: kTextSizeSourceJS.replaceAll(kTextSizePlaceholder, '$kInitialTextSize'),
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START);

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

  int textSize = kInitialTextSize;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Custom Text Size"),
          actions: [
            IconButton(
                onPressed: () async {
                  textSize++;
                  await updateTextSize(textSize);
                },
                icon: const Icon(Icons.add)),
            IconButton(
                onPressed: () async {
                  textSize--;
                  await updateTextSize(textSize);
                },
                icon: const Icon(Icons.remove)),
            TextButton(
              onPressed: () async {
                textSize = kInitialTextSize;
                await updateTextSize(textSize);
              },
              child: const Text(
                'Reset',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: Column(children: <Widget>[
          Expanded(
            child: InAppWebView(
              key: webViewKey,
              initialUrlRequest:
              URLRequest(url: WebUri("https://github.com/flutter")),
              initialUserScripts: UnmodifiableListView(
                  !kIsWeb && defaultTargetPlatform == TargetPlatform.android
                      ? []
                      : [textSizeUserScript]),
              initialSettings: InAppWebViewSettings(textZoom: textSize),
              onWebViewCreated: (controller) async {
                webViewController = controller;
              },
            ),
          ),
        ]));
  }

  updateTextSize(int textSize) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await webViewController?.setSettings(
          settings: InAppWebViewSettings(textZoom: textSize));
    } else {
      // update current text size
      await webViewController?.evaluateJavascript(source: """
              document.body.style.textSizeAdjust = '$textSize%';
              document.body.style.webkitTextSizeAdjust = '$textSize%';
            """);

      // update the User Script for the next page load
      await webViewController?.removeUserScript(userScript: textSizeUserScript);
      textSizeUserScript.source =
          kTextSizeSourceJS.replaceAll(kTextSizePlaceholder, '$textSize');
      await webViewController?.addUserScript(userScript: textSizeUserScript);
    }
  }
}