// lib/services/booking_service.dart - FIXED VERSION
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ✅ GUNA INI untuk type safety
  static CollectionReference<Map<String, dynamic>> get _bookingsRef =>
      _firestore.collection('bookings');

  /// =========================
  /// TODAY BOOKINGS
  /// =========================
  static Stream<List<Booking>> getTodayBookings(String shopId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _bookingsRef
        .where('shopId', isEqualTo: shopId)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('startAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromFirestore(doc))
            .toList());
  }

  /// =========================
  /// PENDING BOOKINGS (ACTION NEEDED)
  /// =========================
  static Stream<List<Booking>> getPendingBookings(String shopId) {
    return _bookingsRef
        .where('shopId', isEqualTo: shopId)
        .where('status', isEqualTo: 'pending')
        .orderBy('startAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromFirestore(doc))
            .toList());
  }

  /// =========================
  /// UPCOMING BOOKINGS (CONFIRMED + FUTURE)
  /// =========================
  static Stream<List<Booking>> getUpcomingBookings(String shopId) {
    final now = Timestamp.now();
    
    return _bookingsRef
        .where('shopId', isEqualTo: shopId)
        .where('status', isEqualTo: 'confirmed')
        .where('startAt', isGreaterThanOrEqualTo: now)
        .orderBy('startAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromFirestore(doc))
            .toList());
  }

  /// =========================
  /// HISTORY BOOKINGS (COMPLETED + CANCELLED)
  /// =========================
  static Stream<List<Booking>> getHistoryBookings(String shopId) {
    return _bookingsRef
        .where('shopId', isEqualTo: shopId)
        .where('status', whereIn: ['completed', 'cancelled'])
        .orderBy('startAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromFirestore(doc))
            .toList());
  }

  /// =========================
  /// UPDATE BOOKING STATUS
  /// =========================
  static Future<void> updateStatus(String bookingId, BookingStatus status) async {
    try {
      await _bookingsRef.doc(bookingId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  /// =========================
  /// UPDATE PAYMENT STATUS
  /// =========================
  static Future<void> updatePaymentStatus(String bookingId, bool isPaid) async {
    try {
      await _bookingsRef.doc(bookingId).update({
        'isPaid': isPaid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  /// =========================
  /// COMPLETE BOOKING
  /// =========================
  static Future<void> completeBooking(String bookingId) async {
    try {
      await _bookingsRef.doc(bookingId).update({
        'status': BookingStatus.completed.name,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to complete booking: $e');
    }
  }

  /// =========================
  /// GET BOOKING BY ID - ✅ FIXED
  /// =========================
  static Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _bookingsRef.doc(bookingId).get();
      if (doc.exists) {
        return Booking.fromFirestore(doc); // ✅ SEKARAN TAK ERROR
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get booking: $e');
    }
  }

  /// =========================
  /// UPDATE BARBER FOR BOOKING
  /// =========================
  static Future<void> updateBookingBarber(
    String bookingId, 
    String barberId, 
    String barberName
  ) async {
    try {
      await _bookingsRef.doc(bookingId).update({
        'barberId': barberId,
        'barberName': barberName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update booking barber: $e');
    }
  }

  /// =========================
  /// GET BOOKING STATS
  /// =========================
  static Future<Map<String, int>> getBookingStats(String shopId) async {
    try {
      final todaySnapshot = await getTodayBookings(shopId).first;
      final pendingSnapshot = await getPendingBookings(shopId).first;
      final upcomingSnapshot = await getUpcomingBookings(shopId).first;

      return {
        'today': todaySnapshot.length,
        'pending': pendingSnapshot.length,
        'upcoming': upcomingSnapshot.length,
      };
    } catch (e) {
      throw Exception('Failed to get booking stats: $e');
    }
  }

  /// =========================
  /// GET BOOKINGS BY BARBER
  /// =========================
  static Stream<List<Booking>> getBookingsByBarber(String shopId, String barberId) {
    return _bookingsRef
        .where('shopId', isEqualTo: shopId)
        .where('barberId', isEqualTo: barberId)
        .orderBy('startAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromFirestore(doc))
            .toList());
  }
}