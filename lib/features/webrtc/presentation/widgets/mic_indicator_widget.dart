import 'package:flutter/material.dart';

class MicIndicatorWidget extends StatelessWidget {
  final Stream<bool> isSpeakingStream;

  const MicIndicatorWidget({Key? key, required this.isSpeakingStream}) : super(key: key);

  @override
  Widget build(key) {
    return StreamBuilder<bool>(
      stream: isSpeakingStream,
      initialData: false,
      builder: (context, snapshot) {
        bool isSpeaking = snapshot.data ?? false;

        return AnimatedContainer(
          duration: Duration(milliseconds: 150),
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSpeaking ? Colors.green.withOpacity(0.8) : Colors.black45,
            shape: BoxShape.circle,
            boxShadow: isSpeaking ? [
              BoxShadow(
                color: Colors.green.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 3,
              )
            ] : [],
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