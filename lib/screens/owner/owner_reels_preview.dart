// lib/screens/owner/owner_reels_preview.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'owner_reels_management.dart';
import 'owner_reels_upload.dart';

class OwnerReelsPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> reel;
  
  const OwnerReelsPreviewScreen({super.key, required this.reel});

  @override
  State<OwnerReelsPreviewScreen> createState() => _OwnerReelsPreviewScreenState();
}

class _OwnerReelsPreviewScreenState extends State<OwnerReelsPreviewScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final db = FirebaseFirestore.instance;
  
  VideoPlayerController? _videoController;
  bool _videoPlaying = false;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.reel['videoUrl']));
    await _videoController!.initialize();
    setState(() {});
  }

  void _toggleVideoPlayback() {
    if (_videoController != null) {
      if (_videoPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      setState(() => _videoPlaying = !_videoPlaying);
    }
  }

  Future<void> _publishReel() async {
    setState(() => _publishing = true);
    
    try {
      await db.collection('reels').doc(widget.reel['reelId']).update({
        'status': 'published',
        'publishedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Reel published! Now visible in feed.')),
      );
      
      // Navigate back to management screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const OwnerReelsManagementScreen()),
        (route) => false,
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish: $e')),
      );
    } finally {
      setState(() => _publishing = false);
    }
  }

  void _editReel() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OwnerReelsUploadScreen()),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: _toggleVideoPlayback,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 400,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: VideoPlayer(_videoController!),
            ),
          ),
          if (!_videoPlaying)
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
            ),
        ],
      ),
    );
  }

  Widget _buildReelInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.reel['caption'] ?? 'No caption',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (widget.reel['tags'] != null && (widget.reel['tags'] as List).isNotEmpty)
            Wrap(
              spacing: 8,
              children: (widget.reel['tags'] as List).map<Widget>((tag) {
                return Chip(
                  label: Text('#$tag'),
                  backgroundColor: Colors.blue[50],
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.reel['status'] == 'published' ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.reel['status'] == 'published' ? Colors.green : Colors.orange,
                  ),
                ),
                child: Text(
                  widget.reel['status'] == 'published' ? 'PUBLISHED' : 'DRAFT',
                  style: TextStyle(
                    color: widget.reel['status'] == 'published' ? Colors.green[700] : Colors.orange[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.reel['filter'] != null && widget.reel['filter'] != 'none')
                Text(
                  'Filter: ${widget.reel['filter']}',
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preview Reel"),
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
          children: [
            _buildVideoPlayer(),
            const SizedBox(height: 20),
            _buildReelInfo(),
            const SizedBox(height: 24),
            
            if (widget.reel['status'] != 'published') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editReel,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Again'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _publishing ? null : _publishReel,
                      icon: _publishing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                          : const Icon(Icons.publish),
                      label: Text(_publishing ? 'Publishing...' : 'Publish Now'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const OwnerReelsManagementScreen()),
                      (route) => false,
                    );
                  },
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