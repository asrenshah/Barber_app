import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'owner_reels_upload.dart';

class OwnerReelsPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> reel;
  
  const OwnerReelsPreviewScreen({super.key, required this.reel});

  @override
  State<OwnerReelsPreviewScreen> createState() => _OwnerReelsPreviewScreenState();
}

class _OwnerReelsPreviewScreenState extends State<OwnerReelsPreviewScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;
  bool _isPublishing = false;
  
  Duration _videoDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.pause();
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      final videoUrl = widget.reel['videoUrl'];
      if (videoUrl == null || videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }

      _videoController = VideoPlayerController.network(videoUrl)
        ..addListener(_videoListener);

      await _videoController.initialize();
      
      _videoDuration = _videoController.value.duration;
      
      await _videoController.play();
      
      setState(() {
        _isVideoInitialized = true;
        _isVideoPlaying = true;
      });
      
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _videoListener() {
    if (!mounted) return;
    
    setState(() {
      _currentPosition = _videoController.value.position;
      _isVideoPlaying = _videoController.value.isPlaying;
      
      if (_videoController.value.position >= _videoDuration && 
          _videoController.value.isPlaying) {
        _videoController.seekTo(Duration.zero);
      }
    });
  }

  Future<void> _toggleVideoPlayback() async {
    if (!_isVideoInitialized) return;
    
    try {
      if (_isVideoPlaying) {
        await _videoController.pause();
      } else {
        await _videoController.play();
      }
    } catch (e) {
      print('Error toggling playback: $e');
    }
  }

  Future<void> _publishReel() async {
    if (_isPublishing) return;
    
    setState(() => _isPublishing = true);
    
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      
      final reelId = widget.reel['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      await _firestore.collection('reels').doc(reelId).update({
        'status': 'published',
        'publishedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Reel published successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pop(context, true);
      
    } catch (e) {
      print('Error publishing reel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  Future<void> _editReel() {
    return Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OwnerReelsUpload(reelData: widget.reel),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading video...'),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleVideoPlayback,
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: VideoPlayer(_videoController),
            ),
            
            if (!_isVideoPlaying)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReelInfo() {
    final caption = widget.reel['caption'] ?? 'No caption';
    final hashtags = List<String>.from(widget.reel['hashtags'] ?? []);
    final status = widget.reel['status'] ?? 'draft';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          
          if (hashtags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: hashtags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.reel['status'] ?? 'draft';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Reel'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildVideoPlayer(),
            const SizedBox(height: 24),
            
            _buildReelInfo(),
            const SizedBox(height: 32),
            
            if (status != 'published') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editReel,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isPublishing ? null : _publishReel,
                      icon: _isPublishing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.publish),
                      label: Text(_isPublishing ? 'Publishing...' : 'Publish Now'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Back to Reels Management'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}