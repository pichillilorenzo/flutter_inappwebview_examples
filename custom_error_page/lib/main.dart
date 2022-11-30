import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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

  handleClick(int item) {
    switch (item) {
      case 0:
        webViewController?.loadUrl(
            urlRequest:
                URLRequest(url: WebUri('https://www.notawebsite..com/')));
        break;
      case 1:
        webViewController?.loadUrl(
            urlRequest: URLRequest(url: WebUri('https://google.com/404')));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Custom Error Page"),
          actions: [
            PopupMenuButton<int>(
              onSelected: (item) => handleClick(item),
              itemBuilder: (context) => [
                const PopupMenuItem<int>(
                    value: 0, child: Text('Test web page loading error')),
                const PopupMenuItem<int>(
                    value: 1, child: Text('Test 404 error')),
              ],
            ),
          ],
        ),
        body: Column(children: <Widget>[
          Expanded(
            child: InAppWebView(
              key: webViewKey,
              initialUrlRequest:
                  URLRequest(url: WebUri('https://github.com/flutter')),
              initialSettings:
                  InAppWebViewSettings(disableDefaultErrorPage: true),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onReceivedHttpError: (controller, request, errorResponse) async {
                // Handle HTTP errors here
                var isForMainFrame = request.isForMainFrame ?? false;
                if (!isForMainFrame) {
                  return;
                }

                final snackBar = SnackBar(
                  content: Text(
                      'HTTP error for URL: ${request.url} with Status: ${errorResponse.statusCode} ${errorResponse.reasonPhrase ?? ''}'),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
              onReceivedError: (controller, request, error) async {
                // Handle web page loading errors here
                var isForMainFrame = request.isForMainFrame ?? false;
                if (!isForMainFrame ||
                    (!kIsWeb &&
                        defaultTargetPlatform == TargetPlatform.iOS &&
                        error.type == WebResourceErrorType.CANCELLED)) {
                  return;
                }

                var errorUrl = request.url;
                controller.loadData(data: """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <style>
    ${await InAppWebViewController.tRexRunnerCss}
    </style>
    <style>
    .interstitial-wrapper {
        box-sizing: border-box;
        font-size: 1em;
        line-height: 1.6em;
        margin: 0 auto 0;
        max-width: 600px;
        width: 100%;
    }
    </style>
</head>
<body>
    ${await InAppWebViewController.tRexRunnerHtml}
    <div class="interstitial-wrapper">
      <h1>Website not available</h1>
      <p>Could not load web pages at <strong>$errorUrl</strong> because:</p>
      <p>${error.description}</p>
    </div>
</body>
    """, baseUrl: errorUrl, historyUrl: errorUrl);
              },
            ),
          ),
        ]));
  }
}
