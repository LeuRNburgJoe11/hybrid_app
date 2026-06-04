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
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/nxlink_logo.png',
          height: 32,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: const Center(
        child: Text(
          'Chatbot loads here',
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
