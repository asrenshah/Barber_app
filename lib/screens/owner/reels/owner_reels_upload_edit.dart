import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class OwnerReelsUpload extends StatefulWidget {
  final Map<String, dynamic>? reelData;
  
  const OwnerReelsUpload({
    super.key,
    this.reelData,
  });

  @override
  _OwnerReelsUploadState createState() => _OwnerReelsUploadState();
}

class _OwnerReelsUploadState extends State<OwnerReelsUpload> {
  File? _videoFile;
  VideoPlayerController? _videoController;
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _hashtagsController = TextEditingController();
  String? _selectedSoundId;
  double _videoVolume = 1.0;
  double _musicVolume = 0.5;
  bool _isUploading = false;
  bool _isVideoPlaying = false;
  bool _isEditingMode = false;
  double _videoDuration = 0;
  double _currentPosition = 0;

  final List<Map<String, dynamic>> _soundLibrary = [
    {
      'id': 'none',
      'title': 'No Music (Original Audio)',
      'artist': 'Video Original',
      'category': 'Original',
      'icon': Icons.music_off,
    },
    {
      'id': 'upbeat',
      'title': 'Upbeat Corporate',
      'artist': 'No Copyright Sounds',
      'category': 'Corporate',
      'icon': Icons.business_center,
    },
    {
      'id': 'chill',
      'title': 'Chill Vibes',
      'artist': 'Royalty Free',
      'category': 'Relax',
      'icon': Icons.self_improvement,
    },
    {
      'id': 'funny',
      'title': 'Funny Sound Effects',
      'artist': 'SFX Library',
      'category': 'Comedy',
      'icon': Icons.mood,
    },
    {
      'id': 'nature',
      'title': 'Nature Sounds',
      'artist': 'Natural',
      'category': 'Ambient',
      'icon': Icons.nature,
    },
    {
      'id': 'epic',
      'title': 'Epic Cinematic',
      'artist': 'Free Music',
      'category': 'Dramatic',
      'icon': Icons.movie,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedSoundId = 'none';
    
    if (widget.reelData != null) {
      _isEditingMode = true;
      _loadExistingReelData(widget.reelData!);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  void _loadExistingReelData(Map<String, dynamic> data) {
    try {
      if (data['caption'] != null) {
        _captionController.text = data['caption'];
      }
      
      if (data['hashtags'] != null) {
        final hashtags = List<String>.from(data['hashtags']);
        _hashtagsController.text = hashtags.map((h) => '#$h').join(' ');
      }
      
      if (data['sound'] != null && data['sound'] is Map) {
        final sound = data['sound'] as Map<String, dynamic>;
        _selectedSoundId = sound['id'] ?? 'none';
        _videoVolume = sound['videoVolume'] ?? 1.0;
        _musicVolume = sound['musicVolume'] ?? 0.5;
      }
      
      setState(() {});
    } catch (e) {
      print('Error loading existing reel data: $e');
    }
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );

    if (video != null) {
      final File videoFile = File(video.path);
      
      final fileSize = await videoFile.length();
      if (fileSize > 50 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video terlalu besar (max 50MB)')),
        );
        return;
      }

      setState(() {
        _videoFile = videoFile;
      });

      _initializeVideoPlayer(videoFile);
    }
  }

  void _initializeVideoPlayer(File videoFile) {
    _videoController?.dispose();
    
    _videoController = VideoPlayerController.file(videoFile)
      ..initialize().then((_) {
        setState(() {
          _videoDuration = _videoController!.value.duration.inSeconds.toDouble();
          _videoController!.play();
          _isVideoPlaying = true;
        });
        
        _videoController!.addListener(() {
          setState(() {
            _currentPosition = _videoController!.value.position.inSeconds.toDouble();
          });
        });
      });
  }

  void _togglePlayPause() {
    if (_videoController != null) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        setState(() => _isVideoPlaying = false);
      } else {
        _videoController!.play();
        setState(() => _isVideoPlaying = true);
      }
    }
  }

  Future<String?> _uploadVideoToStorage() async {
    if (_videoFile == null) return null;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final String reelId = _isEditingMode && widget.reelData?['id'] != null
          ? widget.reelData!['id']
          : DateTime.now().millisecondsSinceEpoch.toString();
          
      final String storagePath = 'reels/${user.uid}/$reelId/video.mp4';

      final Reference storageRef = FirebaseStorage.instance.ref(storagePath);
      final UploadTask uploadTask = storageRef.putFile(_videoFile!);

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading video: $e');
      return null;
    }
  }

  Future<void> _saveReelToFirestore(String videoUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final reelId = _isEditingMode && widget.reelData?['id'] != null
        ? widget.reelData!['id']
        : DateTime.now().millisecondsSinceEpoch.toString();
    
    final List<String> hashtags = _hashtagsController.text
        .split(' ')
        .where((tag) => tag.startsWith('#'))
        .map((tag) => tag.replaceAll('#', '').toLowerCase())
        .toList();

    final selectedSound = _soundLibrary.firstWhere(
      (sound) => sound['id'] == _selectedSoundId,
      orElse: () => _soundLibrary[0],
    );

    // SIMPLE VERSION - NO COMPLEX CONDITIONS
    final Map<String, dynamic> reelData = {
      'id': reelId,
      'shopId': user.uid,
      'videoUrl': videoUrl,
      'thumbnailUrl': '',
      'caption': _captionController.text.trim(),
      'hashtags': hashtags,
      'sound': {
        'id': selectedSound['id'],
        'title': selectedSound['title'],
        'artist': selectedSound['artist'],
        'videoVolume': _videoVolume,
        'musicVolume': _musicVolume,
      },
      'duration': _videoDuration.round(),
      'views': 0,
      'likes': 0,
      'comments': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'publishedAt': FieldValue.serverTimestamp(),
      'status': 'published',
      'isActive': true,
    };

    // Jika edit mode, keep existing stats
    if (_isEditingMode && widget.reelData != null) {
      reelData['views'] = widget.reelData!['views'] ?? 0;
      reelData['likes'] = widget.reelData!['likes'] ?? 0;
      reelData['comments'] = widget.reelData!['comments'] ?? 0;
      reelData['createdAt'] = widget.reelData!['createdAt'] ?? FieldValue.serverTimestamp();
      reelData['publishedAt'] = widget.reelData!['publishedAt'] ?? FieldValue.serverTimestamp();
    }

    try {
      await FirebaseFirestore.instance
          .collection('reels')
          .doc(reelId)
          .set(reelData, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditingMode 
                ? 'Reel berjaya dikemaskini!' 
                : 'Reel berjaya diupload!'
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error saving reel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSave() async {
    if (!_isEditingMode && _videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila pilih video terlebih dahulu')),
      );
      return;
    }

    if (_captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila masukkan caption')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String videoUrl;
      
      if (_isEditingMode && _videoFile == null) {
        videoUrl = widget.reelData!['videoUrl'];
      } else {
        final uploadedUrl = await _uploadVideoToStorage();
        if (uploadedUrl == null) {
          throw Exception('Video upload failed');
        }
        videoUrl = uploadedUrl;
      }
      
      await _saveReelToFirestore(videoUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditingMode ? 'Edit Reel' : 'Upload Reel Baru'),
        actions: [
          if (_videoFile != null || _isEditingMode)
            IconButton(
              icon: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.check),
              onPressed: _isUploading ? null : _handleSave,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditingMode)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Edit Mode: Updating existing reel',
                        style: TextStyle(color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ),
              ),
            
            _buildVideoPreview(),
            const SizedBox(height: 20),

            const Text('Caption', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _captionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Tulis caption untuk reel anda...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Hashtags', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _hashtagsController,
              decoration: const InputDecoration(
                hintText: '#barber #hairstyle #malaysia',
                border: OutlineInputBorder(),
                prefixText: '#',
              ),
            ),
            const SizedBox(height: 20),

            const Text('Pilih Sound/Music', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildSoundSelector(),
            const SizedBox(height: 20),

            if (_selectedSoundId != 'none') ...[
              const Text('Volume Control', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildVolumeControls(),
              const SizedBox(height: 20),
            ],

            if (_videoFile == null && !_isEditingMode)
              ElevatedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.video_library),
                label: const Text('Pilih Video dari Gallery'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_videoFile == null && !_isEditingMode) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, size: 50, color: Colors.grey[500]),
            const SizedBox(height: 10),
            const Text('No video selected'),
            const Text('Max: 60 seconds, 50MB', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }
    
    if (_isEditingMode && _videoFile == null) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library, size: 50, color: Colors.blue),
            const SizedBox(height: 10),
            const Text('Using existing video'),
            const Text('Pilih video baru jika nak ganti', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Ganti Video'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_videoController != null && _videoController!.value.isInitialized)
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              
              IconButton(
                icon: Icon(
                  _isVideoPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: 50,
                  color: Colors.white.withOpacity(0.8),
                ),
                onPressed: _togglePlayPause,
              ),

              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    Text(
                      '${_currentPosition.round()}s',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _videoDuration > 0 ? _currentPosition / _videoDuration : 0,
                        backgroundColor: Colors.grey[700],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    ),
                    Text(
                      '${_videoDuration.round()}s',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _pickVideo,
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Ganti Video'),
        ),
      ],
    );
  }

  Widget _buildSoundSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: _soundLibrary.map((sound) {
          final bool isSelected = _selectedSoundId == sound['id'];
          
          return ListTile(
            leading: Icon(sound['icon'] as IconData, color: isSelected ? Colors.blue : Colors.grey),
            title: Text(sound['title']),
            subtitle: Text('${sound['artist']} • ${sound['category']}'),
            trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
            onTap: () {
              setState(() => _selectedSoundId = sound['id']);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVolumeControls() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.volume_up),
          title: const Text('Video Audio'),
          subtitle: Slider(
            value: _videoVolume,
            min: 0.0,
            max: 1.0,
            onChanged: (value) {
              setState(() => _videoVolume = value);
            },
          ),
          trailing: Text('${(_videoVolume * 100).round()}%'),
        ),
        ListTile(
          leading: const Icon(Icons.music_note),
          title: const Text('Background Music'),
          subtitle: Slider(
            value: _musicVolume,
            min: 0.0,
            max: 1.0,
            onChanged: (value) {
              setState(() => _musicVolume = value);
            },
          ),
          trailing: Text('${(_musicVolume * 100).round()}%'),
        ),
      ],
    );
  }
}