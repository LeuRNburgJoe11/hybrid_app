import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ResizableVideoTile extends StatefulWidget {
  final RTCVideoRenderer renderer;
  final String label;

  const ResizableVideoTile({Key? key, required this.renderer, required this.label}) : super(key: key);

  @override
  _ResizableVideoTileState createState() => _ResizableVideoTileState();
}

class _ResizableVideoTileState extends State<ResizableVideoTile> {
  // Set default dimensions multipliers (1.0 = standard baseline size)
  double _sizeMultiplier = 1.0;

  @override
  Widget build(BuildContext context) {
    // Standard baseline card dimensions
    double baseWidth = 200.0;
    double baseHeight = 150.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The dynamic resizing video tile container
        AnimatedContainer(
          duration: const Duration(milliseconds: 100), // Smooth scaling animations
          width: baseWidth * _sizeMultiplier,
          height: baseHeight * _sizeMultiplier,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black87,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              RTCVideoView(widget.renderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: Colors.black54,
                  child: Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
        
        // Sizing Slider Control
        SizedBox(
          width: baseWidth,
          child: Slider(
            value: _sizeMultiplier,
            min: 0.6,  // Minimum shrink limit
            max: 1.8,  // Maximum expansion limit
            divisions: 6,
            activeColor: Colors.blueAccent,
            onChanged: (double newValue) {
              setState(() {
                _sizeMultiplier = newValue;
              });
            },
          ),
        ),
      ],
    );
  }
}