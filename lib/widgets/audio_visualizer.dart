import 'package:flutter/material.dart';
import '../services/native_features_service.dart';

class AudioVisualizer extends StatefulWidget {
  final bool isRecording;

  const AudioVisualizer({super.key, required this.isRecording});

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with TickerProviderStateMixin {
  double _audioLevel = 0.0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    if (widget.isRecording) {
      _startListening();
    }
  }

  void _startListening() {
    NativeFeaturesService.audioLevelStream.listen((level) {
      if (mounted && widget.isRecording) {
        setState(() {
          _audioLevel = level.clamp(0.0, 1.0);
        });
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
      }
    });
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(20, (index) {
          final barHeight = widget.isRecording
              ? (20 + (_audioLevel * 40 * (0.5 + (index % 3) * 0.3)))
              : 20.0;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 3,
            height: barHeight,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: widget.isRecording
                  ? Colors.red.withOpacity(0.7 + (_audioLevel * 0.3))
                  : Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}