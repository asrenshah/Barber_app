// lib/screens/customer/widgets/reel_video_player.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ReelVideoPlayer extends StatefulWidget {
  final Map<String, dynamic> reel;
  final String reelId;
  final Map<String, VideoPlayerController> videoControllers;
  final Map<String, ChewieController> chewieControllers;
  final VoidCallback onLike;
  final VoidCallback onShopTap;

  const ReelVideoPlayer({
    super.key,
    required this.reel,
    required this.reelId,
    required this.videoControllers,
    required this.chewieControllers,
    required this.onLike,
    required this.onShopTap,
  });

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> {
  bool _showControls = false;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() async {
    if (widget.videoControllers.containsKey(widget.reelId)) return;

    try {
      final videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.reel['videoUrl']),
      );
      
      await videoController.initialize();

      final chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: true,
        looping: true,
        showControls: false,
        allowMuting: false,
        allowPlaybackSpeedChanging: false,
        allowedScreenSleep: false,
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 50),
                  const SizedBox(height: 16),
                  Text(
                    'Video loading error',
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      setState(() {
        widget.videoControllers[widget.reelId] = videoController;
        widget.chewieControllers[widget.reelId] = chewieController;
      });
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  // ✅ TAMBAHAN: Double-tap to like dengan animation
  void _doubleTapLike() {
    widget.onLike();
    setState(() {
      _isLiked = true;
    });
    
    // Reset like animation after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLiked = false;
        });
      }
    });
  }

  // ✅ TAMBAHAN: Auto-hide controls setelah 3 saat
  void _toggleControls() {
    setState(() {
      _showControls = true;
    });
    
    // Auto-hide controls after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });
    widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    final hasVideoController = widget.chewieControllers.containsKey(widget.reelId);

    return GestureDetector(
      onTap: _toggleControls,
      onDoubleTap: _doubleTapLike, // ✅ TAMBAHAN: Double-tap feature
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Background
          if (hasVideoController)
            Chewie(controller: widget.chewieControllers[widget.reelId]!)
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // ✅ TAMBAHAN: Like Animation (Double-tap)
          if (_isLiked)
            Center(
              child: Icon(
                Icons.favorite,
                color: Colors.white,
                size: 120,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.pink.withOpacity(0.8),
                  ),
                ],
              ),
            ),

          // Gradient Overlay (DARI CODE ANDA - BAIK!)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),

          // Content Overlay (DARI CODE ANDA - BAIK!)
          if (_showControls) ...[
            // Top Shop Info (DARI CODE ANDA - BAIK!)
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: widget.onShopTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.store, size: 16, color: Colors.black),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.reel['shopName'] ?? 'Shop',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 14, color: Colors.blue),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Content (DARI CODE ANDA - BAIK!)
            Positioned(
              bottom: 100,
              left: 16,
              right: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Caption
                  Text(
                    widget.reel['caption'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Tags
                  if (widget.reel['tags'] != null && (widget.reel['tags'] as List).isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: (widget.reel['tags'] as List).map<Widget>((tag) {
                        return Text(
                          '#$tag',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            // Right Action Buttons (DARI CODE ANDA - BAIK!)
            Positioned(
              bottom: 120,
              right: 16,
              child: Column(
                children: [
                  // Like Button
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : Colors.white,
                          size: 32,
                        ),
                        onPressed: _toggleLike,
                      ),
                      Text(
                        '${widget.reel['likes'] ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Comment Button
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.comment, color: Colors.white, size: 32),
                        onPressed: () {
                          // TODO: Implement comments
                        },
                      ),
                      Text(
                        '${widget.reel['comments']?.length ?? 0}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Share Button
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white, size: 32),
                    onPressed: () {
                      // TODO: Implement share
                    },
                  ),
                ],
              ),
            ),
          ],

          // Play/Pause Indicator (DARI CODE ANDA - BAIK!)
          if (!_showControls && hasVideoController)
            Positioned(
              bottom: 120,
              right: 16,
              child: Column(
                children: [
                  // Like Heart Animation Placeholder
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Controllers disposed in parent widget
    super.dispose();
  }
}