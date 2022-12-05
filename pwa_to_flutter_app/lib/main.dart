import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import 'webview_popup.dart';
import 'constants.dart';
import 'util.dart';

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

// Use WidgetsBindingObserver to listen when the app goes in background
// to stop, on Android, JavaScript execution and any processing that can be paused safely,
// such as videos, audio, and animations.
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  InAppWebViewSettings sharedSettings = InAppWebViewSettings(
      // enable opening windows support
      supportMultipleWindows: true,
      javaScriptCanOpenWindowsAutomatically: true,

      // useful for identifying traffic, e.g. in Google Analytics.
      applicationNameForUserAgent: 'My PWA App Name',
      // Override the User Agent, otherwise some external APIs, such as Google and Facebook logins, will not work
      // because they recognize and block the default WebView User Agent.
      userAgent:
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.5304.105 Mobile Safari/537.36',
      disableDefaultErrorPage: true,

      // enable iOS service worker feature limited to defined App Bound Domains
      limitsNavigationsToAppBoundDomains: true);

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    webViewController = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb) {
      if (webViewController != null &&
          defaultTargetPlatform == TargetPlatform.android) {
        if (state == AppLifecycleState.paused) {
          pauseAll();
        } else {
          resumeAll();
        }
      }
    }
  }

  void pauseAll() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      webViewController?.pause();
    }
    webViewController?.pauseTimers();
  }

  void resumeAll() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      webViewController?.resume();
    }
    webViewController?.resumeTimers();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // detect Android back button click
        final controller = webViewController;
        if (controller != null) {
          if (await controller.canGoBack()) {
            controller.goBack();
            return false;
          }
        }
        return true;
      },
      child: Scaffold(
          appBar: AppBar(
            // remove the toolbar
            toolbarHeight: 0,
          ),
          body: Column(children: <Widget>[
            Expanded(
              child: Stack(
                children: [
                  FutureBuilder<bool>(
                    future: isNetworkAvailable(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container();
                      }

                      final bool networkAvailable = snapshot.data ?? false;

                      // Android-only
                      final cacheMode = networkAvailable
                          ? CacheMode.LOAD_DEFAULT
                          : CacheMode.LOAD_CACHE_ELSE_NETWORK;

                      // iOS-only
                      final cachePolicy = networkAvailable
                          ? URLRequestCachePolicy.USE_PROTOCOL_CACHE_POLICY
                          : URLRequestCachePolicy.RETURN_CACHE_DATA_ELSE_LOAD;

                      final webViewInitialSettings = sharedSettings.copy();
                      webViewInitialSettings.cacheMode = cacheMode;

                      return InAppWebView(
                        key: webViewKey,
                        initialUrlRequest:
                            URLRequest(url: kPwaUri, cachePolicy: cachePolicy),
                        initialUserScripts: UnmodifiableListView<UserScript>([
                          UserScript(
                              source: """
                              document.getElementById('notifications').addEventListener('click', function(event) {
                                var randomText = Math.random().toString(36).slice(2, 7);
                                window.flutter_inappwebview.callHandler('requestDummyNotification', randomText);
                              });
                              """,
                              injectionTime:
                                  UserScriptInjectionTime.AT_DOCUMENT_END)
                        ]),
                        initialSettings: webViewInitialSettings,
                        onWebViewCreated: (controller) {
                          webViewController = controller;

                          controller.addJavaScriptHandler(
                            handlerName: 'requestDummyNotification',
                            callback: (arguments) {
                              final String randomText =
                                  arguments.isNotEmpty ? arguments[0] : '';
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(randomText)));
                            },
                          );
                        },
                        shouldOverrideUrlLoading:
                            (controller, navigationAction) async {
                          // restrict navigation to target host, open external links in 3rd party apps
                          final uri = navigationAction.request.url;
                          if (uri != null &&
                              navigationAction.isForMainFrame &&
                              uri.host != kPwaHost &&
                              await canLaunchUrl(uri)) {
                            launchUrl(uri);
                            return NavigationActionPolicy.CANCEL;
                          }
                          return NavigationActionPolicy.ALLOW;
                        },
                        onLoadStop: (controller, url) async {
                          if (await isNetworkAvailable() &&
                              !(await isPWAInstalled())) {
                            // if network is available and this is the first time
                            setPWAInstalled();
                          }
                        },
                        onReceivedError: (controller, request, error) async {
                          final isForMainFrame = request.isForMainFrame ?? true;
                          if (isForMainFrame && !(await isNetworkAvailable())) {
                            if (!(await isPWAInstalled())) {
                              await controller.loadData(
                                  data: kHTMLErrorPageNotInstalled);
                            }
                          }
                        },
                        onCreateWindow: (controller, createWindowAction) async {
                          showDialog(
                            context: context,
                            builder: (context) {
                              final popupWebViewSettings =
                                  sharedSettings.copy();
                              popupWebViewSettings.supportMultipleWindows =
                                  false;
                              popupWebViewSettings
                                      .javaScriptCanOpenWindowsAutomatically =
                                  false;

                              return WebViewPopup(
                                  createWindowAction: createWindowAction,
                                  popupWebViewSettings: popupWebViewSettings);
                            },
                          );
                          return true;
                        },
                      );
                    },
                  )
                ],
              ),
            ),
          ])),
    );
  }
}
