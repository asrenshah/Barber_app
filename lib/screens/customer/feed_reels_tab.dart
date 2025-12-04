import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'widgets/reel_video_player.dart';

class FeedReelsTab extends StatefulWidget {
  const FeedReelsTab({super.key});

  @override
  State<FeedReelsTab> createState() => _FeedReelsTabState();
}

class _FeedReelsTabState extends State<FeedReelsTab> {
  final PageController _pageController = PageController();
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, ChewieController> _chewieControllers = {};

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    for (var controller in _chewieControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int index) {
    // Optional: Jika perlu tracking current page untuk analytics atau lain-lain
    // print('Current page: $index');
  }

  void _likeReel(String reelId, Map<String, dynamic> reel) {
    final currentLikes = reel['likes'] ?? 0;
    FirebaseFirestore.instance.collection('reels').doc(reelId).update({
      'likes': currentLikes + 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // ✅ TAMBAH: Like feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Liked! ❤️'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _visitShopProfile(String shopId) {
    // TODO: Implement shop profile navigation
    print('Navigating to shop: $shopId');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reels')
          .where('status', isEqualTo: 'published')
          .orderBy('publishedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No reels yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Shop owners will start uploading content soon!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
                // ✅ TAMBAH: Refresh button
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        final reels = snapshot.data!.docs;

        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: reels.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            final reel = reels[index].data() as Map<String, dynamic>;
            final reelId = reels[index].id;

            return ReelVideoPlayer(
              reel: reel,
              reelId: reelId,
              videoControllers: _videoControllers,
              chewieControllers: _chewieControllers,
              onLike: () => _likeReel(reelId, reel),
              onShopTap: () => _visitShopProfile(reel['shopId']),
            );
          },
        );
      },
    );
  }
}