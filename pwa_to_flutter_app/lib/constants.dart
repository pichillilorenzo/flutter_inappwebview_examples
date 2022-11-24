import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// PWA Url
final kPwaUri = WebUri('https://mdn.github.io/pwa-examples/js13kpwa/');
final kPwaHost = kPwaUri.host;

// Custom HTML Error Page.
const kHTMLErrorPage = """
<html>
  <head></head>
  <body>
    <h1>Not connected to Internet :(</h1>
  </body>
</html>
""";

// Custom HTML Error Page if the App has not been installed correctly the first time.
const kHTMLErrorPageNotInstalled = """
<html>
  <head></head>
  <body>
    <h1>You must be connected to Internet at least one time to install correctly the App.</h1>
  </body>
</html>
""";