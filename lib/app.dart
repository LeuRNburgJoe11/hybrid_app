import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// ── NXLink brand tokens ───────────────────────────────────────────────────────
const _kGreen = Color(0xFF6BBF4E);
const _kGreenDark = Color(0xFF3B6B35);
const _kGreenLight = Color(0xFFEDF7E6);
const _kNavy = Color(0xFF1C2B3A);
const _kBodyGrey = Color(0xFF4A5568);

class MyHybridApp extends StatelessWidget {
  const MyHybridApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NXLINK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _kGreen,
          primary: _kGreen,
          onPrimary: Colors.white,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleSpacing: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _kNavy,
            height: 1.25,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kNavy,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: _kBodyGrey,
            height: 1.6,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            color: _kBodyGrey,
            letterSpacing: 0.4,
          ),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

// ── Welcome / landing screen ──────────────────────────────────────────────────
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        children: [
          // ── Hero banner ───────────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.only(top: 64, bottom: 40, left: 28, right: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/hi_nxlink_logo.jpg',
                  height: 36,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 28),
                Text(
                  'Redefine Customer\nExperience with NXLINK',
                  style: tt.displaySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'A comprehensive CX platform integrating AI\nto revolutionize customer experiences.',
                  style: tt.bodyMedium,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChatbotShell()),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Start Chat'),
                ),
              ],
            ),
          ),

          // ── Feature highlights ─────────────────────────────────────────────
          Expanded(
            child: Container(
              color: _kGreenLight,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Next-Generation AI-Powered CX', style: tt.titleLarge),
                  const SizedBox(height: 20),
                  _FeatureTile(
                    icon: Icons.hub_outlined,
                    title: 'Omni-channel Interactions',
                    body: 'Seamless engagement across websites, social media, live chat, and phone calls.',
                  ),
                  _FeatureTile(
                    icon: Icons.auto_graph,
                    title: 'Predictive AI Outbound',
                    body: 'Boost engagement with AI-driven predictive calling and automated responses.',
                  ),
                  _FeatureTile(
                    icon: Icons.support_agent,
                    title: 'Proactive Customer Service',
                    body: 'AI push notifications and two-way conversational automation — no wait, no repeat.',
                  ),
                  _FeatureTile(
                    icon: Icons.smart_toy_outlined,
                    title: 'Conversational AI Assistant',
                    body: 'Intelligent self-service powered by large language models, available 24/7.',
                  ),
                  const SizedBox(height: 8),

                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'Over 2,000 Global Companies Grow with NXLINK',
                      textAlign: TextAlign.center,
                      style: tt.titleLarge?.copyWith(color: _kGreen, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chatbot shell (your WebView will replace the placeholder body) ─────────────
class ChatbotShell extends StatelessWidget {
  const ChatbotShell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/nxlink_logo.png',
          height: 30,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _kNavy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Column(
        children: [
          // Status chip
          Container(
            width: double.infinity,
            color: _kGreenLight,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _kGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Assistant · Online',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: _kGreenDark, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // NXLink chatbot WebView
          Expanded(
            child: InAppWebView(
              initialData: InAppWebViewInitialData(
                data: '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #ffffff; }
  </style>
</head>
<body>
  <script>
    const script = document.createElement('script');
    script.id = 'live-chat-script';
    script.src = 'https://nxlink.nxcloud.com/chatbot/client/js/live_chat.min.js?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ0ZW5hbnRfaWQiOiIzMDE1IiwiYXVkIjoiVmlzaXRvciBDbGllbnQiLCJjb25maWdfaWQiOiIxNCIsIm5hbWUiOiJMaXZlIENoYXQiLCJpc3MiOiJueGFpLmNvbSIsImV4cCI6NDgyNzU2MTM3MSwiaWF0IjoxNzUxNzIxMzcxfQ.KaZg8EiYf8IW0tubuAufaQ7UZaExpzprDVwiylCltSw&vtime=' + new Date().getTime();
    document.head.appendChild(script);
  </script>
</body>
</html>
''',
                mimeType: 'text/html',
                encoding: 'utf-8',
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                useOnLoadResource: true,
                useShouldOverrideUrlLoading: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ───────────────────────────────────────────────────────────
class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kGreenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _kGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: tt.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700, color: _kNavy)),
                const SizedBox(height: 4),
                Text(body, style: tt.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              height: 1.4,
            )),
      ],
    );
  }
}
