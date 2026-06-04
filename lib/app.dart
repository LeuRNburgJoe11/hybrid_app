import 'package:flutter/material.dart';

class MyHybridApp extends StatelessWidget {
  const MyHybridApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hybrid App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ChatbotShell(),
    );
  }
}

/// ChatbotShell is a placeholder for your chatbot WebView.
/// Replace this with your actual WebView widget integration.
class ChatbotShell extends StatelessWidget {
  const ChatbotShell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Chatbot loads here',
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
