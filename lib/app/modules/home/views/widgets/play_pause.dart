import 'package:audio_service/audio_service.dart';
import 'package:audiobooks/app/modules/audio/audio_controller.dart';
import 'package:audiobooks/app/modules/splash/controllers/splash_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/get_state_manager.dart';

class PlayPauseButton extends GetView<AudioController> {
  const PlayPauseButton(
      {Key? key,
      required this.audioFilePath,
      this.onPressed,
      this.size,
      this.child})
      : super(key: key);

  final String audioFilePath;
  final VoidCallback? onPressed;
  final double? size;
  final Widget? child;
  // @override
  // String? get tag => entryName;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        /// Starts the background audio service if it has been disabled
        /// on the service UI
        if (!AudioService.running) await startBackgroundAudioService();

        controller.playing
            ? controller.pause()
            : controller.play(audioFilePath);
        if (onPressed != null) {
          onPressed!();
        }
      },
      child: child ??
          Center(
              child: Obx(() => Icon(
                    controller.playing && controller.audioPath == audioFilePath
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_fill_rounded,
                    size: size ?? 40.0,
                    color: const Color(0xFF2E429C),
                  ))),
    );
  }
}
