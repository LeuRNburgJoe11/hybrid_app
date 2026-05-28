# hybrid_app

A cross-platform Flutter application featuring AI Voice Chatbot integration and WebRTC capabilities.


## Getting Started on Flutter 

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## 🛠️ Environment Prerequisites (Windows Users)

Before running or testing this application locally on Windows, ensure your Flutter SDK and Pub Cache paths **do not contain spaces** (e.g., avoid placing them in `OneDrive` or `Users/Your Name`). 

If you encounter native asset compilation errors, configure a dedicated, space-free Pub Cache:
1. Set a global environment variable: `PUB_CACHE` = `C:\src\.pub-cache`
2. Ensure your Flutter SDK is located in a path like `C:\src\flutter`.

---

## How to Run & Test this App

This app uses conditional platform rendering to support Mobile, Desktop, and Web.

### 1. Testing on Web (Chrome / Edge)
Testing on the web uses an optimized HTML iframe mockup for rapid UI development.
```bash
# Clean previous builds
flutter clean
flutter pub get

# Launch on Chrome
flutter run -d chrome

### 1. Testing on Mobile Emulators (Android / iOS)

To test full native webview_flutter features and actual platform interactions, run the app on a mobile emulator:

# View connected devices and emulators
flutter devices

# Run on your chosen mobile target
flutter run -d <device_id>

------
## Chatbot JSP Embedding Guide

The Chatbot interface (lib/features/chatbot/chatbot_screen.dart) embeds a web-based chatbot UI. It is designed to switch seamlessly between a mock local testing phase and your live production JSP environment.
Architectural Setup

The app dynamically identifies the hosting platform at runtime:

    Web Targets: Uses a native browser HTMLIFrameElement (srcdoc) to render layouts cleanly without plugin overhead.

    Mobile Targets: Leverages native webview_flutter components.

Switching from Mock Mode to Live JSP Production

Currently, the screen loads a native HTML string mockup for local styling and Riverpod state testing. When your JSP backend is live, update the source destination:

    Open lib/features/chatbot/chatbot_screen.dart.

    Locate the initState() block.

    Change the data injection source:

For Mobile WebView:
Swap out _controller!.loadHtmlString(_mockHtmlString); with your live JSP URL network request:

_controller!.loadRequest(Uri.parse('[https://your-production-server.com/chatbot.jsp](https://your-production-server.com/chatbot.jsp)'));

For Web Iframe View:
Swap out the ..srcdoc = _mockHtmlString.toJS; initialization line with a standard network source property:

final iframe = web.HTMLIFrameElement()
  ..style.border = 'none'
  ..style.width = '100%'
  ..style.height = '100%'
  ..src = '[https://your-production-server.com/chatbot.jsp'.toJS](https://
  your-production-server.com/chatbot.jsp'.toJS); // Changed srcdoc to src

Important Security Note for Web Testing: Modern browsers enforce CORS (Cross-Origin Resource Sharing) rules. Ensure your production JSP server includes the appropriate security headers (X-Frame-Options or Content-Security-Policy) allowing your Flutter Web domain to frame the webpage, otherwise Chrome will block the connection.

---