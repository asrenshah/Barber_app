import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:barber_app/models/reel_model.dart';
import 'package:barber_app/screens/customer/widgets/reel_video_player.dart';

class FeedReelsTab extends StatefulWidget {
  const FeedReelsTab({super.key});

  @override
  State<FeedReelsTab> createState() => _FeedReelsTabState();
}

class _FeedReelsTabState extends State<FeedReelsTab>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, ChewieController> _chewieControllers = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _currentPageIndex = 0;
  final bool _isTabActive = true;
  bool _showUI = true;
  List<Reel> _reels = [];
  bool _isLoading = true;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 10;
  
  // 🎯 FIX: Flag untuk block multiple initialization
  bool _isInitializing = false;
  String? _currentlyPlayingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialReels();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseAllVideos();
    } else if (state == AppLifecycleState.resumed && _isTabActive) {
      _playCurrentVideo();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _disposeAllControllers();
    super.dispose();
  }

  void _disposeAllControllers() {
    for (final controller in _videoControllers.values) {
      controller.pause();
      controller.dispose();
    }
    for (final controller in _chewieControllers.values) {
      controller.pause();
      controller.dispose();
    }
    _videoControllers.clear();
    _chewieControllers.clear();
  }

  void _pauseAllVideos() {
    for (final controller in _chewieControllers.values) {
      controller.pause();
    }
  }

  void _playCurrentVideo() {
    if (_reels.isNotEmpty && _currentPageIndex < _reels.length) {
      final reelId = _reels[_currentPageIndex].id;
      _playSingleVideo(reelId);
    }
  }
  
  // 🎯 FIX: Method untuk play SATU video sahaja
  void _playSingleVideo(String reelId) {
    // Pause semua video dulu
    for (final id in _chewieControllers.keys) {
      if (id != reelId) {
        _chewieControllers[id]?.pause();
      }
    }
    
    // Play video yang dipilih
    if (_chewieControllers.containsKey(reelId)) {
      _chewieControllers[reelId]?.play();
      _currentlyPlayingId = reelId;
    }
  }

  Future<void> _loadInitialReels() async {
    try {
      final query = _firestore
          .collection('reels')
          .where('status', isEqualTo: 'published')
          .where('isPublic', isEqualTo: true)
          .orderBy('publishedAt', descending: true)
          .limit(_pageSize);

      final snapshot = await query.get();

      setState(() {
        _reels = snapshot.docs
            .map((doc) => Reel.fromFirestore(doc))
            .toList();
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == _pageSize;
        _isLoading = false;
      });

      if (_reels.isNotEmpty) {
        _initializeVideoController(_reels.first);
      }
    } catch (e) {
      debugPrint('Error loading reels: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreReels() async {
    if (!_hasMore || _isLoading) return;

    try {
      final query = _firestore
          .collection('reels')
          .where('status', isEqualTo: 'published')
          .where('isPublic', isEqualTo: true)
          .orderBy('publishedAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          final newReels = snapshot.docs
              .map((doc) => Reel.fromFirestore(doc))
              .toList();
          _reels.addAll(newReels);
          _lastDocument = snapshot.docs.last;
          _hasMore = snapshot.docs.length == _pageSize;
        });
      } else {
        setState(() => _hasMore = false);
      }
    } catch (e) {
      debugPrint('Error loading more reels: $e');
    }
  }

  // 🎯 FIX: Initialize dengan audio management
  void _initializeVideoController(Reel reel) async {
    if (_videoControllers.containsKey(reel.id) || _isInitializing) return;
    
    _isInitializing = true;
    
    try {
      final videoController = VideoPlayerController.networkUrl(
        Uri.parse(reel.videoUrl),
        // 🚨 PENTING: mixWithOthers: false supaya audio tak overlap
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );

      await videoController.initialize();

      final chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: _currentPageIndex == 0 && _isTabActive,
        looping: true,
        showControls: false,
        allowMuting: true,
        allowPlaybackSpeedChanging: false,
        allowedScreenSleep: false,
        // 🎯 Additional options untuk stability
        aspectRatio: videoController.value.aspectRatio,
        placeholder: Container(color: Colors.black),
      );

      setState(() {
        _videoControllers[reel.id] = videoController;
        _chewieControllers[reel.id] = chewieController;
      });
      
      // 🎯 Jika ini video current, play
      if (reel.id == _reels[_currentPageIndex].id) {
        _playSingleVideo(reel.id);
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    } finally {
      _isInitializing = false;
    }
  }

  // 🎯 FIX: Page changed dengan audio management
  void _onPageChanged(int index) {
    // Pause video sebelumnya
    if (_currentPageIndex < _reels.length) {
      final prevReelId = _reels[_currentPageIndex].id;
      if (_chewieControllers.containsKey(prevReelId)) {
        _chewieControllers[prevReelId]?.pause();
      }
    }

    setState(() => _currentPageIndex = index);

    if (index < _reels.length) {
      final currentReel = _reels[index];
      
      if (!_videoControllers.containsKey(currentReel.id)) {
        _initializeVideoController(currentReel);
      } else {
        _playSingleVideo(currentReel.id);
      }

      _incrementViewCount(currentReel.id);
    }

    // Preload video berikutnya
    if (index < _reels.length - 1) {
      final nextReel = _reels[index + 1];
      if (!_videoControllers.containsKey(nextReel.id)) {
        _initializeVideoController(nextReel);
      }
    }

    if (index >= _reels.length - 3) {
      _loadMoreReels();
    }
  }

  void _incrementViewCount(String reelId) {
    _firestore.collection('reels').doc(reelId).update({
      'views': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _toggleUI() {
    setState(() => _showUI = !_showUI);
  }

  void _likeReel(String reelId) {
    final reelIndex = _reels.indexWhere((reel) => reel.id == reelId);
    if (reelIndex != -1) {
      setState(() {
        _reels[reelIndex].isLikedByUser = !_reels[reelIndex].isLikedByUser;
        _reels[reelIndex].likes += _reels[reelIndex].isLikedByUser ? 1 : -1;
      });

      _firestore.collection('reels').doc(reelId).update({
        'likes': _reels[reelIndex].likes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No reels available'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadInitialReels,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildLoadingState()
          : _reels.isEmpty
              ? _buildEmptyState()
              : Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: _reels.length + (_hasMore ? 1 : 0),
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        if (index >= _reels.length) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final reel = _reels[index];
                        
                        // 🎯 FIX: Jangan panggil initialize di sini
                        // Controller akan di-initialize oleh _onPageChanged
                        
                        return ReelVideoPlayer(
                          reel: reel,
                          videoController: _videoControllers[reel.id],
                          chewieController: _chewieControllers[reel.id],
                          showUI: _showUI,
                          onLike: () => _likeReel(reel.id),
                          onToggleUI: _toggleUI,
                          onShopTap: () {
                            debugPrint('Navigate to shop: ${reel.shopId}');
                          },
                          onCommentTap: () {
                            debugPrint('Open comments for: ${reel.id}');
                          },
                          onShareTap: () {
                            debugPrint('Share reel: ${reel.id}');
                          },
                        );
                      },
                    ),

                    Positioned(
                      top: MediaQuery.of(context).padding.top + 16,
                      right: 16,
                      child: IconButton(
                        icon: Icon(
                          _showUI ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white,
                        ),
                        onPressed: _toggleUI,
                      ),
                    ),

                    if (_hasMore && _reels.length >= _pageSize)
                      Positioned(
                        bottom: 100,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Loading more...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}