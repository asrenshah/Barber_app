// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  // Singleton
  FirestoreService._privateConstructor();
  static final FirestoreService instance = FirestoreService._privateConstructor();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Simpan user baru (customer atau shop owner)
  Future<void> createUser({
    required String uid,
    required String email,
    required String userType, // "customer" | "shop_owner"
    required String name,
    required String phone,
    String? shopName,
    String? shopAddress,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'userType': userType,
        'name': name,
        'phone': phone,
        'shopName': shopName,
        'shopAddress': shopAddress,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Simpan kedai baru (untuk shop owner)
  Future<String> createShop({
    required String ownerId,
    required String shopName,
    required String address,
  }) async {
    try {
      final shopRef = _db.collection('shops').doc();
      await shopRef.set({
        'ownerId': ownerId,
        'shopName': shopName,
        'address': address,
        'services': [],
        'workingHours': <String, dynamic>{},
        'createdAt': FieldValue.serverTimestamp(),
      });
      return shopRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// 🎯 FIXED: Simpan booking baru - SUPPORT BOTH STRUCTURES
  Future<String> createBooking({
    required String shopId,
    required String customerId,
    required String serviceName,
    required DateTime time,
    double price = 0.0,
    String? customerName,
    String? customerPhone,
    String? shopName,
    bool isWalkIn = false,
  }) async {
    try {
      final bookingRef = _db.collection('bookings').doc();
      
      // Format date string untuk dashboard service
      final dateStr = DateFormat('yyyy-MM-dd').format(time);
      final timeStr = DateFormat('HH:mm').format(time);
      
      await bookingRef.set({
        // ✅ NEW STRUCTURE (untuk booking service)
        'shopId': shopId,
        'customerId': customerId,
        'customerName': customerName ?? 'Customer',
        'customerPhone': customerPhone,
        'serviceName': serviceName,
        'price': price,
        'startAt': Timestamp.fromDate(time), // Untuk booking service
        'status': 'pending',
        'isPaid': false,
        'isWalkIn': isWalkIn,
        
        // ✅ OLD STRUCTURE (untuk dashboard service)
        'date': dateStr,  // Untuk dashboard service
        'time': timeStr,  // Untuk dashboard service
        'service': serviceName, // Backup untuk compatibility
        
        // Common fields
        'shopName': shopName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return bookingRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Kembalikan user doc
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) async {
    return await _db.collection('users').doc(uid).get();
  }

  /// Dapatkan semua shops (stream)
  Stream<QuerySnapshot<Map<String, dynamic>>> getShops() {
    return _db.collection('shops').snapshots();
  }

  /// Dapatkan semua bookings untuk satu shop (by shopId)
  /// 🎯 FIXED: Support both query methods
  Stream<QuerySnapshot<Map<String, dynamic>>> getBookingsForShop(String shopId) {
    // Boleh guna 'date' atau 'startAt' bergantung pada keperluan
    return _db
        .collection('bookings')
        .where('shopId', isEqualTo: shopId)
        .orderBy('date') // Guna date untuk compatibility
        .snapshots();
  }

  /// Dapatkan semua bookings untuk satu customer
  Stream<QuerySnapshot<Map<String, dynamic>>> getBookingsForCustomer(
      String customerId) {
    return _db
        .collection('bookings')
        .where('customerId', isEqualTo: customerId)
        .orderBy('date') // Guna date untuk compatibility
        .snapshots();
  }

  /// (Helper) Update status booking - SUPPORT BOTH SERVICES
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _db.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// (Optional) jika perlukan query by shop owner
  Stream<QuerySnapshot<Map<String, dynamic>>> getBookingsByOwner(String ownerId) {
    return _db
        .collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('date')
        .snapshots();
  }
  
  /// 🎯 NEW: Helper untuk migrate data lama ke baru
  Future<void> migrateOldBookings(String shopId) async {
    try {
      final snapshot = await _db
          .collection('bookings')
          .where('shopId', isEqualTo: shopId)
          .get();
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Jika ada date & time tapi takda startAt
        if (data['date'] != null && data['time'] != null && data['startAt'] == null) {
          final dateStr = data['date'] as String;
          final timeStr = data['time'] as String;
          
          try {
            // Parse date + time to DateTime
            final dateTimeStr = '${dateStr}T$timeStr:00';
            final dateTime = DateTime.parse(dateTimeStr);
            
            await doc.reference.update({
              'startAt': Timestamp.fromDate(dateTime),
              'serviceName': data['service'] ?? data['serviceName'] ?? 'Service',
            });
            print('Migrated booking: ${doc.id}');
          } catch (e) {
            print('Failed to migrate booking ${doc.id}: $e');
          }
        }
      }
    } catch (e) {
      print('Migration error: $e');
    }
  }
}