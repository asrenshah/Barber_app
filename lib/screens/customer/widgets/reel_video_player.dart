import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../models/reel_model.dart';

class ReelVideoPlayer extends StatefulWidget {
  final Reel reel;
  final VideoPlayerController? videoController;
  final ChewieController? chewieController;
  final bool showUI;
  final VoidCallback onLike;
  final VoidCallback onToggleUI;
  final VoidCallback onShopTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;

  const ReelVideoPlayer({
    super.key,
    required this.reel,
    this.videoController,
    this.chewieController,
    required this.showUI,
    required this.onLike,
    required this.onToggleUI,
    required this.onShopTap,
    required this.onCommentTap,
    required this.onShareTap,
  });

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> {
  bool _isLiked = false;
  bool _isSaved = false;
  bool _showControlsOverlay = false;
  bool _isPlaying = true;
  
  // 🎯 FIX: Debouncing flags
  bool _isProcessingTap = false;
  bool _isProcessingDoubleTap = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.reel.isLikedByUser;
    _isSaved = widget.reel.isSavedByUser;
    
    if (widget.videoController != null) {
      widget.videoController!.addListener(_videoListener);
    }
  }

  void _videoListener() {
    if (widget.videoController != null && mounted) {
      final isPlaying = widget.videoController!.value.isPlaying;
      if (isPlaying != _isPlaying) {
        setState(() => _isPlaying = isPlaying);
      }
    }
  }

  @override
  void dispose() {
    widget.videoController?.removeListener(_videoListener);
    super.dispose();
  }

  // 🎯 FIX: Debounced play/pause
  void _togglePlayPause() async {
    if (_isProcessingTap || widget.chewieController == null) return;
    
    _isProcessingTap = true;
    
    if (widget.chewieController!.isPlaying) {
      widget.chewieController!.pause();
    } else {
      widget.chewieController!.play();
    }
    
    await Future.delayed(const Duration(milliseconds: 300));
    _isProcessingTap = false;
  }

  // 🎯 FIX: Debounced double tap
  void _doubleTapLike() async {
    if (_isProcessingDoubleTap) return;
    
    _isProcessingDoubleTap = true;
    
    if (!_isLiked) {
      setState(() => _isLiked = true);
      widget.onLike();
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    _isProcessingDoubleTap = false;
  }

  void _toggleControls() {
    setState(() => _showControlsOverlay = true);
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControlsOverlay) {
        setState(() => _showControlsOverlay = false);
      }
    });
  }

  void _toggleSave() {
    setState(() => _isSaved = !_isSaved);
  }

  Widget _buildShopInfo() {
    return GestureDetector(
      onTap: widget.onShopTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: widget.reel.shopAvatar != null && widget.reel.shopAvatar!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(widget.reel.shopAvatar!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: widget.reel.shopAvatar == null ? Colors.white : null,
              ),
              child: widget.reel.shopAvatar == null
                  ? const Icon(Icons.store, size: 16, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              widget.reel.shopName,
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
    );
  }

  Widget _buildCaptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.reel.caption,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        
        if (widget.reel.hashtags.isNotEmpty)
          Wrap(
            spacing: 8,
            children: widget.reel.hashtags.map<Widget>((tag) {
              return GestureDetector(
                onTap: () {},
                child: Text(
                  '#$tag',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        
        const SizedBox(height: 8),
        Text(
          '${widget.reel.formattedViews} views • ${widget.reel.timeSincePublished}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required IconData? activeIcon,
    required String count,
    required bool isActive,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(
            isActive ? (activeIcon ?? icon) : icon,
            color: isActive ? (activeColor ?? Colors.red) : Colors.white,
            size: 32,
          ),
          onPressed: onTap,
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRightActionPanel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildActionButton(
          icon: Icons.favorite_border,
          activeIcon: Icons.favorite,
          count: widget.reel.formattedLikes,
          isActive: _isLiked,
          onTap: () {
            setState(() => _isLiked = !_isLiked);
            widget.onLike();
          },
          activeColor: Colors.red,
        ),
        const SizedBox(height: 20),
        
        _buildActionButton(
          icon: Icons.comment,
          activeIcon: null,
          count: widget.reel.comments.toString(),
          isActive: false,
          onTap: widget.onCommentTap,
        ),
        const SizedBox(height: 20),
        
        _buildActionButton(
          icon: Icons.share,
          activeIcon: null,
          count: '',
          isActive: false,
          onTap: widget.onShareTap,
        ),
        const SizedBox(height: 20),
        
        _buildActionButton(
          icon: Icons.bookmark_border,
          activeIcon: Icons.bookmark,
          count: '',
          isActive: _isSaved,
          onTap: _toggleSave,
          activeColor: Colors.yellow,
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    if (widget.chewieController != null && widget.chewieController!.videoPlayerController.value.isInitialized) {
      return Chewie(controller: widget.chewieController!);
    }
    
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              widget.videoController == null ? 'Loading video...' : 'Initializing player...',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showContent = widget.showUI && _showControlsOverlay;

    return GestureDetector(
      onTap: () {
        _toggleControls();
        _togglePlayPause(); // 🎯 Tap untuk play/pause
      },
      onDoubleTap: _doubleTapLike,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideoPlayer(),
          
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
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          if (showContent) ...[
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShopInfo(),
                  IconButton(
                    icon: const Icon(Icons.visibility_off, color: Colors.white),
                    onPressed: widget.onToggleUI,
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 120,
              left: 16,
              right: 100,
              child: _buildCaptionSection(),
            ),

            Positioned(
              bottom: 120,
              right: 16,
              child: _buildRightActionPanel(),
            ),

            if (!_isPlaying)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
          ] else if (widget.showUI) ...[
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: Opacity(
                opacity: 0.7,
                child: _buildShopInfo(),
              ),
            ),

            Positioned(
              bottom: 120,
              right: 24,
              child: Column(
                children: [
                  Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.white,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.reel.formattedLikes,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_isLiked && showContent)
            Center(
              child: Icon(
                Icons.favorite,
                color: Colors.white,
                size: 120,
                shadows: [
                  Shadow(
                    blurRadius: 20,
                    color: Colors.red.withOpacity(0.8),
                  ),
                ],
              ),
            ),

          if (!widget.showUI)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'UI Hidden',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}