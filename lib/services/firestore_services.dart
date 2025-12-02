// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Singleton
  FirestoreService._privateConstructor();
  static final FirestoreService instance = FirestoreService._privateConstructor();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Simpan user baru (customer atau shop owner)
  /// Menggunakan SetOptions(merge: true) supaya tidak overwrite data sedia ada.
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
      // biarkan caller handle error; rethrow supaya stack trace tidak hilang
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

  /// Simpan booking baru (customer buat appointment)
  /// NOTE: Simpankan kedua-dua bentuk masa: `time` sebagai Timestamp (untuk query) dan
  /// `time_iso` sebagai String (untuk backward compatibility).
  Future<String> createBooking({
    required String shopId,
    required String customerId,
    required String service,
    required DateTime time,
    String? shopName, // optional convenience field
  }) async {
    try {
      final bookingRef = _db.collection('bookings').doc();
      await bookingRef.set({
        'shopId': shopId,
        'customerId': customerId,
        'service': service,
        'time': Timestamp.fromDate(time), // native timestamp
        'time_iso': time.toIso8601String(), // legacy-friendly
        'shopName': shopName,
        'status': 'pending',
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
  Stream<QuerySnapshot<Map<String, dynamic>>> getBookingsForShop(String shopId) {
    return _db
        .collection('bookings')
        .where('shopId', isEqualTo: shopId)
        .orderBy('time') // memudahkan ordering (sokong Timestamp)
        .snapshots();
  }

  /// Dapatkan semua bookings untuk satu customer
  Stream<QuerySnapshot<Map<String, dynamic>>> getBookingsForCustomer(
      String customerId) {
    return _db
        .collection('bookings')
        .where('customerId', isEqualTo: customerId)
        .orderBy('time')
        .snapshots();
  }

  /// (Helper) Update status booking
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
        .orderBy('time')
        .snapshots();
  }
}
