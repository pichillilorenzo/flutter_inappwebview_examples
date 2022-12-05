# Third-party OAuth user sign-in

Add support for third-party OAuth user sign-in services, such as Google OAuth Sign-In service.

For example, from Google [Modernizing OAuth interactions in Native Apps for Better Usability and Security](https://developers.googleblog.com/2016/08/modernizing-oauth-interactions-in-native-apps.html) article:

    On April 20, 2017, we will start blocking OAuth requests using web-views for all OAuth clients on platforms where viable alternatives exist.

Google allows sign-in with Google Account only in normal browsers, it restricts it in web-views due to security reasons and recommends Google SDKs for iOS and Android for this purpose.

A similar behaviour exists for Facebook login.

In general, these services recognize the default WebView user agent, so to make it work, you could just set a custom user agent value.

![Android example](https://user-images.githubusercontent.com/5956938/204262729-f5921f45-e65d-4b8a-ae63-9a989923f63f.gif)
![iOS example](https://user-images.githubusercontent.com/5956938/204262731-203e98ae-699d-455b-9ba1-8b3930c9b048.gif)
