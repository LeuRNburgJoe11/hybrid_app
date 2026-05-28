import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class LocalVideoRenderer extends StatelessWidget {
  final RTCVideoRenderer renderer;
  const LocalVideoRenderer({Key? key, required this.renderer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: RTCVideoView(renderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
      ),
    );
  }
}