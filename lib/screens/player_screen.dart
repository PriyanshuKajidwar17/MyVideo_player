import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class PlayerScreen extends StatefulWidget {
  final String videoPath;

  const PlayerScreen({super.key, required this.videoPath});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController controller;

  bool showControls = true;
  bool isLocked = false;
  bool isLandscape = false;

  double playbackSpeed = 1.0;
  double volume = 0.5;
  double brightness = 0.5;

  Timer? sleepTimer;
  Timer? hideTimer;

  late AnimationController _animController;

  String gestureText = "";
  double gestureOpacity = 0;

  bool showLockEffect = false;
  bool showPlayEffect = false;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          controller.play();
        }
      });

    controller.setVolume(volume);

    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    _startHideTimer();
  }

  void _startHideTimer() {
    hideTimer?.cancel();
    hideTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && !isLocked) {
        setState(() => showControls = false);
      }
    });
  }

  void _toggleControls() {
    if (isLocked) return;
    setState(() => showControls = !showControls);
    if (showControls) _startHideTimer();
  }

  void _toggleLock() {
    setState(() {
      isLocked = !isLocked;
      showLockEffect = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => showLockEffect = false);
    });
  }

  void _toggleRotation() {
    setState(() => isLandscape = !isLandscape);

    if (isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  void _togglePlayPause() {
    setState(() {
      controller.value.isPlaying
          ? controller.pause()
          : controller.play();
      showPlayEffect = true;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => showPlayEffect = false);
    });
  }

  /// ✅ FIXED METHODS (ADDED BACK)
  void _changeVolume(bool increase) {
    setState(() {
      volume += increase ? 0.05 : -0.05;
      volume = volume.clamp(0, 1);
      controller.setVolume(volume);
    });
  }

  void _changeBrightness(bool increase) {
    setState(() {
      brightness += increase ? 0.05 : -0.05;
      brightness = brightness.clamp(0, 1);
    });
  }

  void _showGesture(String text) {
    setState(() {
      gestureText = text;
      gestureOpacity = 1;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => gestureOpacity = 0);
    });
  }

  void _setSpeed(double speed) {
    setState(() {
      playbackSpeed = speed;
      controller.setPlaybackSpeed(speed);
    });
  }

  void _setSleepTimer(int minutes) {
    sleepTimer?.cancel();
    sleepTimer = Timer(Duration(minutes: minutes), () {
      controller.pause();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Sleep timer set: $minutes min")),
    );
  }

  void _showVideoDetails() {
    final file = File(widget.videoPath);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Video Details",
                style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 10),
            Text("Name: ${file.path.split('/').last}",
                style: const TextStyle(color: Colors.white)),
            Text(
                "Size: ${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB",
                style: const TextStyle(color: Colors.white)),
            Text("Duration: ${_format(controller.value.duration)}",
                style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  void dispose() {
    controller.dispose();
    sleepTimer?.cancel();
    hideTimer?.cancel();
    _animController.dispose();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReady = controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (isLocked) return;
          _toggleControls();
        },
        onVerticalDragUpdate: (details) {
          final dx = details.localPosition.dx;
          final width = MediaQuery.of(context).size.width;

          if (dx < width / 2) {
            _changeBrightness(details.delta.dy < 0);
          } else {
            _changeVolume(details.delta.dy < 0);
          }
        },
        onDoubleTapDown: (details) {
          final dx = details.localPosition.dx;
          final width = MediaQuery.of(context).size.width;

          if (dx < width / 2) {
            controller.seekTo(
                controller.value.position - const Duration(seconds: 10));
            _showGesture("-10 sec");
          } else {
            controller.seekTo(
                controller.value.position + const Duration(seconds: 10));
            _showGesture("+10 sec");
          }
        },
        child: Stack(
          children: [

            if (isReady)
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),

            if (showPlayEffect || showLockEffect)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.green.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

            if (isLocked)
              Positioned(
                top: 40,
                left: 10,
                child: GestureDetector(
                  onTap: _toggleLock,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock, color: Colors.green),
                  ),
                ),
              ),

            if (showControls && isReady && !isLocked)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Stack(
                    children: [

                      Positioned(
                        top: 40,
                        left: 10,
                        right: 10,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.lock, color: Colors.white),
                              onPressed: _toggleLock,
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  widget.videoPath.split('/').last,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.white),
                              onSelected: (value) {
                                if (value == "rotate") _toggleRotation();
                                if (value == "speed") _showSpeedMenu();
                                if (value == "sleep") _showSleepMenu();
                                if (value == "details") _showVideoDetails();
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: "rotate",
                                  child: Text("Rotate Screen"),
                                ),
                                const PopupMenuItem(value: "speed", child: Text("Playback Speed")),
                                const PopupMenuItem(value: "sleep", child: Text("Sleep Timer")),
                                const PopupMenuItem(value: "details", child: Text("Video Info")),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Center(
                        child: IconButton(
                          icon: Icon(
                            controller.value.isPlaying
                                ? Icons.pause_circle
                                : Icons.play_circle,
                            size: 70,
                            color: Colors.white,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                      ),

                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_format(controller.value.position),
                                    style: const TextStyle(color: Colors.white)),
                                Text(_format(controller.value.duration),
                                    style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                            VideoProgressIndicator(controller, allowScrubbing: true),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isLandscape
                                        ? Icons.screen_lock_rotation
                                        : Icons.screen_rotation,
                                    color: Colors.white,
                                  ),
                                  onPressed: _toggleRotation,
                                ),
                                IconButton(
                                  icon: Icon(
                                    controller.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.green,
                                  ),
                                  onPressed: _togglePlayPause,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSpeedMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [0.5, 1.0, 1.25, 1.5, 2.0].map((s) {
          return ListTile(
            title: Text("${s}x"),
            onTap: () {
              _setSpeed(s);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showSleepMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [5, 10, 30].map((m) {
          return ListTile(
            title: Text("$m min"),
            onTap: () {
              _setSleepTimer(m);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }
}