import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// ── NXLink brand tokens ───────────────────────────────────────────────────────
const _kGreen = Color(0xFF6BBF4E);
const _kGreenDark = Color(0xFF3B6B35);
const _kGreenLight = Color(0xFFEDF7E6);
const _kNavy = Color(0xFF1C2B3A);
const _kBodyGrey = Color(0xFF4A5568);

// Notifier to control the overlayed chatbot visibility
final ValueNotifier<bool> _chatOpenNotifier = ValueNotifier(false);

class MyHybridApp extends StatelessWidget {
  const MyHybridApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EXODUS RETAIL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _kNavy,
          primary: _kNavy,
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
            backgroundColor: _kNavy,
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
      body: Stack(
        children: [
          Column(
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
                  'assets/images/Exodus_Retail_Logo.png',
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 80),
                Text(
                  'Original Designs. Unmatched Quality.',
                  style: tt.displaySmall,
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 60),
                ElevatedButton.icon(
                  onPressed: () {
                    // open the overlayed chatbot instead of navigating
                    _chatOpenNotifier.value = true;
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

          // Chatbot overlay (bottom-right)
          const ChatbotOverlay(),
        ],
      ),
    );
  }
}

// ── Chatbot shell (your WebView will replace the placeholder body) ─────────────
// ── Chatbot shell (Updated) ──────────────────────────────────────────────────
class ChatbotOverlay extends StatefulWidget {
  const ChatbotOverlay({Key? key}) : super(key: key);

  @override
  State<ChatbotOverlay> createState() => _ChatbotOverlayState();
}

class _ChatbotOverlayState extends State<ChatbotOverlay> {
  static const double _panelWidth = 360;
  static const double _panelHeight = 520;

  final String _html = '''
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
    script.src = 'https://nxlink.nxcloud.com/chatbot/client/js/live_chat.min.js?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ0ZW5hbnRfaWQiOiIzMDE1IiwiYXVkIjoiVmlzaXRvciBDbGllbnQiLCJjb25maWdfaWQiOiIxMTIiLCJuYW1lIjoiTGl2ZSBDaGF0IiwiaXNzIjoibnhhaS5jb20iLCJleHAiOjQ4NTY0NzU2NDQsImlhdCI6MTc4MDYzNTY0NH0.zwsgfok3oZBqQHyGjB9BE8uKKUOMvqcjaK3oDnvT9lw&vtime=' + new Date().getTime();

    script.onload = function() {
      setTimeout(function() {
        if (window.NXLiveChat && typeof window.NXLiveChat.open === 'function') {
          window.NXLiveChat.open();
          return;
        }
        const btn = document.querySelector(
          'button, [role="button"], [class*="chat"], [class*="launcher"], [class*="trigger"], [id*="chat"]'
        );
        if (btn) btn.click();
      }, 1500);
    };

    document.head.appendChild(script);
  </script>
</body>
</html>
''';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _chatOpenNotifier,
      builder: (context, open, _) {
        return Positioned(
          bottom: 24,
          right: 24,
          child: open ? _buildPanel(context) : _buildFab(),
        );
      },
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      backgroundColor: _kNavy,
      onPressed: () => _chatOpenNotifier.value = true,
      child: const Icon(Icons.chat_bubble_outline),
    );
  }

  Widget _buildPanel(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: _panelWidth,
        height: _panelHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Image.asset('assets/images/nxlink_logo.png', height: 28),
                  const SizedBox(width: 8),
                  const Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.open_in_full, size: 18),
                    onPressed: () => _chatOpenNotifier.value = false,
                  ),
                ],
              ),
            ),
            Expanded(
              child: InAppWebView(
                initialData: InAppWebViewInitialData(
                  data: _html,
                  mimeType: 'text/html',
                  encoding: 'utf-8',
                  baseUrl: WebUri('https://nxlink.nxcloud.com'),
                ),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  useOnLoadResource: true,
                  useShouldOverrideUrlLoading: true,
                ),
              ),
            ),
          ],
        ),
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

