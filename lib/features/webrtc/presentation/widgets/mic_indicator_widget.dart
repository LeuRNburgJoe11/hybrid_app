import 'package:flutter/material.dart';

class MicIndicatorWidget extends StatelessWidget {
  final Stream<bool> isSpeakingStream;

  const MicIndicatorWidget({Key? key, required this.isSpeakingStream})
      : super(key: key);

  @override
  // FIX: build() must take BuildContext, not Key.
  // The original had `build(key)` which silently shadowed the widget key
  // and broke the context reference inside the builder.
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: isSpeakingStream,
      initialData: false,
      builder: (context, snapshot) {
        final bool isSpeaking = snapshot.data ?? false;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSpeaking
                ? Colors.green.withOpacity(0.8)
                : Colors.black45,
            shape: BoxShape.circle,
            boxShadow: isSpeaking
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 3,
                    )
                  ]
                : [],
          ),
          child: Icon(
            isSpeaking ? Icons.mic : Icons.mic_none,
            color: Colors.white,
            size: 20,
          ),
        );
      },
    );
  }
}
