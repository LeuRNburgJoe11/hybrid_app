# hybrid_app

A cross-platform Flutter application focused on WebRTC audio/video calling, session signaling, and modular service integration.

## Project Overview

`hybrid_app` is built with Flutter and Riverpod. It provides:
- native WebRTC video call rendering via `flutter_webrtc`
- socket-based signaling with `socket_io_client`
- REST session management through a local API service
- an included Node.js signaling server sample for WebRTC offer/answer exchange

## Key Features

- Full-screen remote video display with local preview overlay
- Native media capture for camera and microphone
- WebRTC ICE configuration ready for STUN/TURN deployment
- Session lifecycle state management with Riverpod
- Local backend service scaffolding in `lib/features/webrtc/services/server.js`

## Prerequisites

- Flutter SDK compatible with Dart `>=3.11.0`
- Node.js installed to run the signaling server
- Windows path recommendations:
  - Avoid spaces in Flutter SDK and Pub Cache paths
  - Prefer paths such as `C:\src\flutter` and `C:\src\.pub-cache`

## Setup

1. Install Flutter dependencies:
```bash
flutter clean
flutter pub get
```

2. Install Node dependencies for the signaling server (if you plan to run it locally):
```bash
cd lib/features/webrtc/services
npm install express socket.io
```

## Running the App

### Run on Chrome
```bash
flutter run -d chrome
```

### Run on a connected device or emulator
```bash
flutter devices
flutter run -d <device_id>
```

## Local Signaling Server

A sample signaling server is included at `lib/features/webrtc/services/server.js`.

To run it locally:
```bash
node lib/features/webrtc/services/server.js
```

The app is configured to use `AppConstants.baseUrl` from `lib/core/constants.dart`, which currently points to:
```dart
static const String baseUrl = 'http://localhost:3000';
```

Update this value if your backend runs on a different host or port.

## Architecture

- `lib/main.dart`: Flutter app entrypoint
- `lib/app.dart`: MaterialApp and home screen builder
- `lib/features/webrtc/presentation/video_view.dart`: UI for local/remote video streams
- `lib/features/webrtc/services/webrtc_service.dart`: WebRTC peer connection and signaling logic
- `lib/features/session/providers/session_provider.dart`: session state management
- `lib/features/session/services/api_service.dart`: backend REST API integration

## Important Notes

- The app currently launches the WebRTC video call screen as its home page.
- Replace the placeholder TURN server values in `WebRTCService._iceConfig` with your own secure credentials for production.
- The Node.js signaling server is sample code and should be hardened before production use.

## Dependencies

This app uses:
- `flutter_inappwebview`
- `flutter_webrtc`
- `webview_flutter`
- `socket_io_client`
- `permission_handler`
- `flutter_riverpod`
- `http`

---

## Contribution

Feel free to expand this project by adding:
- a chatbot UI screen with JSP/webview integration
- session creation flows from the Flutter UI
- TURN/STUN server configuration and deployment
- production-ready signaling and authentication
