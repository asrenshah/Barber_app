// lib/screens/owner/owner_reels_upload.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'owner_reels_preview.dart';

class OwnerReelsUploadScreen extends StatefulWidget {
  const OwnerReelsUploadScreen({super.key});

  @override
  State<OwnerReelsUploadScreen> createState() => _OwnerReelsUploadScreenState();
}

class _OwnerReelsUploadScreenState extends State<OwnerReelsUploadScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final db = FirebaseFirestore.instance;
  
  File? _videoFile;
  VideoPlayerController? _videoController;
  bool _uploading = false;
  bool _videoPlaying = false;
  
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  
  // Basic editing options
  double _videoStart = 0.0;
  double _videoEnd = 15.0; // Default 15 seconds
  String _selectedFilter = 'none';
  final List<String> _filters = ['none', 'warm', 'cool', 'vintage', 'bright'];

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? videoFile = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );

    if (videoFile != null) {
      setState(() {
        _videoFile = File(videoFile.path);
      });
      _initializeVideoPlayer();
    }
  }

  void _initializeVideoPlayer() async {
    if (_videoFile != null) {
      _videoController = VideoPlayerController.file(_videoFile!);
      await _videoController!.initialize();
      
      // Set default trim values
      final duration = _videoController!.value.duration.inSeconds.toDouble();
      setState(() {
        _videoEnd = duration > 15.0 ? 15.0 : duration;
      });
      
      _videoController!.addListener(() {
        if (_videoController!.value.position >= Duration(seconds: _videoEnd.toInt())) {
          _videoController!.pause();
          setState(() => _videoPlaying = false);
        }
      });
    }
  }

  void _toggleVideoPlayback() {
    if (_videoController != null) {
      if (_videoPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
        _videoController!.seekTo(Duration(seconds: _videoStart.toInt()));
      }
      setState(() => _videoPlaying = !_videoPlaying);
    }
  }

  Future<void> _uploadReel() async {
    if (_videoFile == null || _captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video and enter caption')),
      );
      return;
    }

    setState(() => _uploading = true);
    
    try {
      // Upload video to Firebase Storage
      final videoRef = FirebaseStorage.instance
          .ref()
          .child('reels')
          .child('${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.mp4');
      
      await videoRef.putFile(_videoFile!);
      final videoUrl = await videoRef.getDownloadURL();

      // Save to Firestore as DRAFT
      final reelRef = db.collection('reels').doc();
      final reelData = {
        'reelId': reelRef.id,
        'shopId': user!.uid,
        'shopName': 'Your Shop', // Boleh fetch dari shop data
        'videoUrl': videoUrl,
        'thumbnailUrl': '', // Placeholder
        'caption': _captionController.text.trim(),
        'tags': _tagsController.text.split(',').map((tag) => tag.trim()).toList(),
        'status': 'draft',
        'filter': _selectedFilter,
        'trimStart': _videoStart,
        'trimEnd': _videoEnd,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'views': 0,
        'comments': [],
      };

      await reelRef.set(reelData);

      // Navigate to preview screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OwnerReelsPreviewScreen(reel: reelData),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎬 Reel uploaded as draft!')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload reel: $e')),
      );
    } finally {
      setState(() => _uploading = false);
    }
  }

  Widget _buildVideoPreview() {
    if (_videoFile == null) {
      return GestureDetector(
        onTap: _pickVideo,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library, size: 50, color: Colors.grey[500]),
              const SizedBox(height: 8),
              const Text('Tap to select video'),
              const Text('(15-60 seconds)', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _toggleVideoPlayback,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _videoController != null && _videoController!.value.isInitialized
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: VideoPlayer(_videoController!),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
              if (!_videoPlaying)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Basic editing controls
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trim Video:', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text('Start: ${_videoStart.toInt()}s'),
                Expanded(
                  child: Slider(
                    value: _videoStart,
                    min: 0,
                    max: _videoEnd - 1,
                    onChanged: (value) {
                      setState(() => _videoStart = value);
                      if (_videoController != null) {
                        _videoController!.seekTo(Duration(seconds: value.toInt()));
                      }
                    },
                  ),
                ),
                Text('End: ${_videoEnd.toInt()}s'),
              ],
            ),
            
            const SizedBox(height: 12),
            const Text('Filter:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedFilter,
              items: _filters.map((filter) {
                return DropdownMenuItem(
                  value: filter,
                  child: Text(filter[0].toUpperCase() + filter.substring(1)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Reel"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_videoFile != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _pickVideo,
              tooltip: 'Change Video',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVideoPreview(),
            
            const SizedBox(height: 20),
            
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                labelText: 'Caption',
                hintText: 'Describe your reel...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 12),
            
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                hintText: 'beauty, haircut, style',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploading ? null : _uploadReel,
                icon: _uploading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                    : const Icon(Icons.upload),
                label: Text(_uploading ? 'Uploading...' : 'Upload as Draft'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}