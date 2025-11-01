import 'package:flutter/material.dart';
import 'package:better_player_plus/better_player_plus.dart';

class WatchScreen extends StatefulWidget {
  final String title;
  final String url360;
  final String url720;

  const WatchScreen({
    super.key,
    required this.title,
    required this.url360,
    required this.url720,
  });

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    final betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.url720,
      cacheConfiguration: const BetterPlayerCacheConfiguration(useCache: true),
      resolutions: {
        "480p": widget.url360,
        "720p": widget.url720,
      },
    );

    _betterPlayerController = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: true,
        fit: BoxFit.contain,
        aspectRatio: 16 / 9,
        allowedScreenSleep: false,
        handleLifecycle: true,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableFullscreen: true,
          enableQualities: true,
          enablePlaybackSpeed: true,
          enableProgressText: true,
          enableOverflowMenu: true,
          enableSkips: false,
          controlBarColor: Colors.black54,
        ),
      ),
      betterPlayerDataSource: betterPlayerDataSource,
    );

    _betterPlayerController.setVolume(1.0);
  }

  @override
  void dispose() {
    _betterPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: BetterPlayer(controller: _betterPlayerController),
        ),
      ),
    );
  }
}
