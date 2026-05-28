import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

class ChatbotBridge {
  late final WebViewController controller;

  void initialize(Function(String) onTextMessageReceived, Function(Map) onVoiceEvent) {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          // Parse the incoming JSON from JSP
          final data = jsonDecode(message.message);
          
          if (data['type'] == 'text') {
            onTextMessageReceived(data['content']);
          } else if (data['type'] == 'voice_signal') {
            // This triggers your WebRTC voice logic (Offer/Answer/ICE)
            onVoiceEvent(data['payload']);
          }
        },
      );
  }

  // Method to send text FROM Flutter TO the JSP Chatbot
  void sendToJsp(String text) {
    final jsonStr = jsonEncode({'type': 'user_input', 'content': text});
    controller.runJavaScript('window.receiveFromFlutter($jsonStr);');
  }
}