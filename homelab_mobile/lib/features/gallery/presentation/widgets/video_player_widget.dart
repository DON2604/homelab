import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:homelab_mobile/core/theme/app_theme.dart';
import 'package:homelab_mobile/features/gallery/domain/models/media_item.dart';

/// Inline video player that streams from `/stream` with play/pause controls
/// and a seek scrubber. Handles its own controller lifecycle safely.
class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({super.key, required this.item});

  final MediaItem item;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final uri = Uri.parse(widget.item.streamUrl);

    final controller = VideoPlayerController.networkUrl(
      uri,
      // No custom headers needed — the server uses standard Range requests
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
    );

    try {
      await controller.initialize();
    } catch (e) {
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
      return;
    }

    if (!mounted) {
      controller.dispose();
      return;
    }

    controller.addListener(_onControllerUpdate);

    setState(() {
      _controller = controller;
      _initialized = true;
    });

    // Auto-play on open
    await controller.play();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final ctrl = _controller;
    if (ctrl == null) return;
    if (ctrl.value.isPlaying) {
      ctrl.pause();
      setState(() => _showControls = true);
    } else {
      ctrl.play();
      setState(() => _showControls = false);
    }
  }

  void _toggleControls() =>
      setState(() => _showControls = !_showControls);

  @override
  Widget build(BuildContext context) {
    if (_hasError) return _ErrorView(message: _errorMessage);
    if (!_initialized || _controller == null) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.accent,
          strokeWidth: 2,
        ),
      );
    }

    final ctrl = _controller!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video frame
          AspectRatio(
            aspectRatio: ctrl.value.aspectRatio,
            child: VideoPlayer(ctrl),
          ),

          // Buffering spinner (shown on top when buffering)
          if (ctrl.value.isBuffering)
            CircularProgressIndicator(
              color: AppTheme.accent,
              strokeWidth: 2,
            ),

          // Controls overlay (tap to toggle)
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: _ControlsOverlay(
                controller: ctrl,
                onPlayPause: _togglePlayPause,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Controls overlay ──────────────────────────────────────────────────────────

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({
    required this.controller,
    required this.onPlayPause,
  });

  final VideoPlayerController controller;
  final VoidCallback onPlayPause;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final position = controller.value.position;
    final duration = controller.value.duration;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withAlpha(100),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withAlpha(180),
          ],
          stops: const [0.0, 0.2, 0.65, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Central play/pause
          Expanded(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPlayPause,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      controller.value.isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      color: Colors.white,
                      size: 64,
                      shadows: const [
                        Shadow(blurRadius: 12, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Seek row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Text(
                  _fmt(position),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                      trackHeight: 3,
                      activeTrackColor: AppTheme.accent,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      overlayColor: AppTheme.accent.withAlpha(60),
                    ),
                    child: Slider(
                      value: progress,
                      onChanged: (v) {
                        final ms = (v * duration.inMilliseconds).round();
                        controller.seekTo(Duration(milliseconds: ms));
                      },
                    ),
                  ),
                ),
                Text(
                  _fmt(duration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_rounded,
                color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Cannot play video',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
