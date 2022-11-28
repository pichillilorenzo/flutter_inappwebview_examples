import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'in_app_browser.dart';

final favoriteURLs = <String>{};

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Custom In-App Browser"),
        ),
        body: ListView(
          children: generateFakePosts(),
        ));
  }

  List<Widget> generateFakePosts() {
    final posts = <Widget>[];
    for (var i = 0; i < 15; i++) {
      posts.add(Card(
          child: ListTile(
            title: Text('Post title ${i + 1}'),
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                "https://picsum.photos/150?random=$i",
              ),
            ),
            subtitle: Text('Subtitle ${i + 1}'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return const CustomInAppBrowser(
                    url: "https://github.com/flutter",
                  );
                },
              ));
            },
          )));
    }
    return posts;
  }
}
