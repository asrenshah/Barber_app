// lib/screens/owner/owner_shop_header.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OwnerShopHeader {
  final User? user;
  final Map<String, dynamic>? shopData;
  final Function(void Function()) setState;
  bool _uploadingProfileImage = false;
  bool _uploadingBannerImage = false;
  
  OwnerShopHeader({
    required this.user,
    required this.shopData,
    required this.setState,
  });

  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<void> uploadShopProfileImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() => _uploadingProfileImage = true);
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('shop_profile_pictures')
            .child('${user!.uid}.jpg');
        
        await storageRef.putFile(File(image.path));
        final downloadURL = await storageRef.getDownloadURL();
        
        await db.collection('shops').doc(user!.uid).set({
          'profileImage': downloadURL,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        setState(() {
          shopData!['profileImage'] = downloadURL;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop profile picture updated!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      } finally {
        setState(() => _uploadingProfileImage = false);
      }
    }
  }

  Future<void> uploadShopBannerImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 400,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() => _uploadingBannerImage = true);
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('shop_banner_images')
            .child('${user!.uid}.jpg');
        
        await storageRef.putFile(File(image.path));
        final downloadURL = await storageRef.getDownloadURL();
        
        await db.collection('shops').doc(user!.uid).set({
          'bannerImage': downloadURL,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        setState(() {
          shopData!['bannerImage'] = downloadURL;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop banner updated!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload banner: $e')),
        );
      } finally {
        setState(() => _uploadingBannerImage = false);
      }
    }
  }

  Widget buildShopHeader(BuildContext context) {
    final hasBanner = shopData?['bannerImage'] != null;
    final hasProfile = shopData?['profileImage'] != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  color: Colors.grey[200],
                  image: hasBanner
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(shopData!['bannerImage']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasBanner
                    ? const Icon(Icons.photo_library, size: 50, color: Colors.grey)
                    : null,
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _uploadingBannerImage ? null : () => uploadShopBannerImage(context),
                    icon: _uploadingBannerImage
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt, size: 20),
                  ),
                ),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: _uploadingProfileImage
                          ? const CircularProgressIndicator()
                          : hasProfile
                              ? CircleAvatar(
                                  backgroundImage: CachedNetworkImageProvider(shopData!['profileImage']),
                                )
                              : CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                  child: Icon(
                                    Icons.business,
                                    size: 40,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                        ),
                        child: IconButton(
                          onPressed: _uploadingProfileImage ? null : () => uploadShopProfileImage(context),
                          icon: Icon(Icons.camera_alt, size: 12, color: Theme.of(context).primaryColor),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopData?['name']?.isNotEmpty == true
                            ? shopData!['name']
                            : 'Nama Kedai Anda',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (shopData?['location']?.isNotEmpty == true)
                        Text(
                          shopData!['location'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              shopData?['category'] ?? 'walk-in',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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