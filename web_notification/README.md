# Web Notification

Example of an implementation of the [Web Notification JavaScript API](https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API).

It uses a [`UserScript`](https://inappwebview.dev/docs/webview/javascript/user-scripts) to inject custom JavaScript code
at web page startup to implement the Web Notification API.

The injected JavaScript code tries to create a "polyfill" for:

- the `Notification` window object
- the `ServiceWorkerRegistration.showNotification` and `ServiceWorkerRegistration.getNotifications` methods

and communicate with Flutter/Dart side using [JavaScript Handlers](https://inappwebview.dev/docs/webview/javascript/communication#JavaScript-Handlers)
to manage and implement the corresponding Notification UI,
for example when you are requesting permission with `Notification.requestPermission()`
or when you want to show a notification, for example:

```javascript
Notification.requestPermission().then(result => {
  if (result === 'granted') {
    const notification = new Notification('Notification Title', {
      body: 'Notification Body!',
      icon: 'https://picsum.photos/250?image=9',
      vibrate: [200, 100, 200]}
    );
    console.log(notification);
  }
});
```

![iOS example](https://user-images.githubusercontent.com/5956938/203871695-7e183f76-36b3-4c5e-bb8f-a4581feb6391.gif)