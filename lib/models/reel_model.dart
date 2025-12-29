// lib/models/reel_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Reel {
  final String id;
  final String shopId;
  String shopName;        // 🎯 BUAT NON-FINAL
  String? shopAvatar;     // 🎯 BUAT NON-FINAL
  final String videoUrl;
  final String? thumbnailUrl;
  final String caption;
  final List<String> hashtags;
  final Map<String, dynamic> sound;
  final int duration;
  int views;              // 🎯 BUAT NON-FINAL
  int likes;              // 🎯 BUAT NON-FINAL
  int comments;           // 🎯 BUAT NON-FINAL
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final String status;
  final bool isActive;
  bool isPublic;          // 🎯 TAMBAH FIELD BARU
  bool isLikedByUser;     // 🎯 TAMBAH FIELD BARU
  bool isSavedByUser;     // 🎯 TAMBAH FIELD BARU

  Reel({
    required this.id,
    required this.shopId,
    required this.shopName,
    this.shopAvatar,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.caption,
    this.hashtags = const [],
    required this.sound,
    required this.duration,
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.status = 'draft',
    this.isActive = true,
    this.isPublic = false,           // 🎯 DEFAULT FALSE
    this.isLikedByUser = false,      // 🎯 DEFAULT FALSE
    this.isSavedByUser = false,      // 🎯 DEFAULT FALSE
  });

  factory Reel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reel(
      id: doc.id,
      shopId: data['shopId'] ?? '',
      shopName: data['shopName'] ?? 'Barbershop',
      shopAvatar: data['shopAvatar'],
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      caption: data['caption'] ?? '',
      hashtags: List<String>.from(data['hashtags'] ?? []),
      sound: Map<String, dynamic>.from(data['sound'] ?? {}),
      duration: data['duration'] ?? 0,
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      publishedAt: data['publishedAt'] != null 
          ? _parseTimestamp(data['publishedAt'])
          : null,
      status: data['status'] ?? 'draft',
      isActive: data['isActive'] ?? true,
      isPublic: data['isPublic'] ?? false,           // 🎯 DARI FIRESTORE
      isLikedByUser: data['isLikedByUser'] ?? false, // 🎯 DARI FIRESTORE
      isSavedByUser: data['isSavedByUser'] ?? false, // 🎯 DARI FIRESTORE
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'shopId': shopId,
      'shopName': shopName,
      'shopAvatar': shopAvatar,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'hashtags': hashtags,
      'sound': sound,
      'duration': duration,
      'views': views,
      'likes': likes,
      'comments': comments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'publishedAt': publishedAt != null 
          ? Timestamp.fromDate(publishedAt!)
          : null,
      'status': status,
      'isActive': isActive,
      'isPublic': isPublic,           // 🎯 SIMPAN KE FIRESTORE
      'isLikedByUser': isLikedByUser, // 🎯 SIMPAN KE FIRESTORE
      'isSavedByUser': isSavedByUser, // 🎯 SIMPAN KE FIRESTORE
    };
  }

  bool get isPublished => status == 'published' && isPublic;
  bool get isDraft => status == 'draft';
  
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  String get formattedViews {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  String get formattedLikes {
    if (likes >= 1000000) {
      return '${(likes / 1000000).toStringAsFixed(1)}M';
    } else if (likes >= 1000) {
      return '${(likes / 1000).toStringAsFixed(1)}K';
    }
    return likes.toString();
  }

  String get timeSincePublished {
    if (publishedAt == null) return 'Not published';
    
    final now = DateTime.now();
    final difference = now.difference(publishedAt!);
    
    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    }
    return 'Just now';
  }
}