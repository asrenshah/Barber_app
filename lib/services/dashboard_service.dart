// lib/services/dashboard_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/barber_model.dart';

class DashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;
  
  DashboardService({required this.userId});
  
  // 🎯 HELPER: Format date (KEEP AS IS - sudah hijau)
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  
  // ========================
  // 1. TODAY'S APPOINTMENTS COUNT - FIXED
  // ========================
  Future<int> getTodayAppointmentsCount() async {
    try {
      final today = DateTime.now();
      final todayStr = _formatDate(today);
      
      // ✅ PASTIKAN INDEX SUDAH DIBUAT UNTUK: shopId + date + __name__
      final snapshot = await _db
          .collection('bookings')
          .where('shopId', isEqualTo: userId)
          .where('date', isEqualTo: todayStr)
          .get();
      
      return snapshot.size;
    } catch (e) {
      print('Error getting today appointments count: $e');
      return 0;
    }
  }
  
  // ========================
  // 2. TODAY'S REVENUE - FIXED
  // ========================
  Future<double> getTodayRevenue() async {
    try {
      final today = DateTime.now();
      final todayStr = _formatDate(today);
      
      // ✅ PASTIKAN INDEX SUDAH DIBUAT UNTUK: shopId + status + date + __name__
      final snapshot = await _db
          .collection('bookings')
          .where('shopId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .where('date', isEqualTo: todayStr)
          .get();
      
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['price'] ?? 0).toDouble();
      }
      
      return total;
    } catch (e) {
      print('Error getting today revenue: $e');
      return 0.0;
    }
  }
  
  // ========================
  // 3. TODAY'S APPOINTMENTS LIST - FIXED
  // ========================
  Future<List<Map<String, dynamic>>> getTodayAppointments() async {
    try {
      final today = DateTime.now();
      final todayStr = _formatDate(today);
      
      // ✅ INDEX YANG PERLU: shopId + date + time + __name__
      // Link yang Firebase beri dalam error:
      // https://console.firebase.google.com/v1/r/project/stylecutz-app/firestore/indexes?create_composite=Ck5wcm9qZWN0cy9zdHlsZWN1dHotYXBwL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9ib29raW5ncy9pbmRleGVzL18QARoICgRkYXRlEAEaCgoGc2hvcElkEAEaCAoEdGltZRABGgwKCF9fbmFtZV9fEAE
      
      final snapshot = await _db
          .collection('bookings')
          .where('shopId', isEqualTo: userId)
          .where('date', isEqualTo: todayStr)
          .orderBy('time')
          .limit(10)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        
        return {
          'id': doc.id,
          'customerName': data['customerName'] ?? 'Unknown',
          'service': data['serviceName'] ?? data['service'] ?? 'Service', // Support both
          'time': data['time'] ?? 'N/A',
          'status': data['status'] ?? 'pending',
          'price': (data['price'] ?? 0).toDouble(),
          'customerPhone': data['customerPhone'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error getting today appointments list: $e');
      return [];
    }
  }
  
  // ========================
  // 4. MONTHLY STATS (SIMPLE) - ALREADY GOOD
  // ========================
  Future<Map<String, dynamic>> getMonthlyStats() async {
    try {
      final now = DateTime.now();
      final currentYearMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      // Last month
      final lastMonthDate = DateTime(now.year, now.month - 1);
      final lastYearMonth = '${lastMonthDate.year}-${lastMonthDate.month.toString().padLeft(2, '0')}';
      
      // ✅ SIMPLE QUERY - NO INDEX NEEDED (sudah baik)
      final allBookingsSnapshot = await _db
          .collection('bookings')
          .where('shopId', isEqualTo: userId)
          .get();
      
      int currentCount = 0;
      int lastCount = 0;
      
      // Filter manually in code (MUDAH & TAK PERLU INDEX)
      for (var doc in allBookingsSnapshot.docs) {
        final data = doc.data();
        final dateStr = data['date'] as String?;
        
        if (dateStr != null) {
          // Current month (contoh: "2024-12-16" starts with "2024-12")
          if (dateStr.startsWith(currentYearMonth)) {
            currentCount++;
          } 
          // Last month (contoh: "2024-11-20" starts with "2024-11")
          else if (dateStr.startsWith(lastYearMonth)) {
            lastCount++;
          }
        }
      }
      
      // Calculate growth
      double growth = 0;
      if (lastCount > 0) {
        growth = ((currentCount - lastCount) / lastCount * 100);
      } else if (currentCount > 0) {
        growth = 100; // First month with bookings
      }
      
      return {
        'currentMonth': currentCount,
        'lastMonth': lastCount,
        'growth': growth,
      };
    } catch (e) {
      print('Error getting monthly stats: $e');
      return {
        'currentMonth': 0,
        'lastMonth': 0,
        'growth': 0.0,
      };
    }
  }
  
  // ========================
  // 5. TOTAL CUSTOMERS - ALREADY GOOD
  // ========================
  Future<int> getTotalCustomers() async {
    try {
      final snapshot = await _db
          .collection('bookings')
          .where('shopId', isEqualTo: userId)
          .get();
      
      final customerPhones = <String>{};
      for (var doc in snapshot.docs) {
        final phone = doc.data()['customerPhone'];
        if (phone != null && phone.isNotEmpty) {
          customerPhones.add(phone);
        }
      }
      
      return customerPhones.length;
    } catch (e) {
      print('Error getting total customers: $e');
      return 0;
    }
  }
  
  // ========================
  // 6. AVERAGE RATING - ALREADY GOOD
  // ========================
  Future<double> getAverageRating() async {
    try {
      final snapshot = await _db
          .collection('reviews')
          .where('shopId', isEqualTo: userId)
          .get();
      
      if (snapshot.size == 0) return 0.0;
      
      double totalRating = 0;
      for (var doc in snapshot.docs) {
        totalRating += (doc.data()['rating'] ?? 0).toDouble();
      }
      
      return totalRating / snapshot.size;
    } catch (e) {
      print('Error getting average rating: $e');
      return 0.0;
    }
  }
  
  // ========================
  // 7. ACTIVE BARBERS - ALREADY GOOD
  // ========================
  Future<List<Barber>> getActiveBarbers() async {
    try {
      final snapshot = await _db
          .collection('shops')
          .doc(userId)
          .collection('barbers')
          .where('isActive', isEqualTo: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Barber.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting active barbers: $e');
      return [];
    }
  }
  
  // ========================
  // 8. NEW: GET PENDING BOOKINGS COUNT (untuk dashboard badge)
  // ========================
  Future<int> getPendingBookingsCount() async {
    try {
      // ✅ GUNA INDEX YANG SAMA DENGAN BOOKING_SERVICE
      final snapshot = await _db
          .collection('bookings')
          .where('shopId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      return snapshot.size;
    } catch (e) {
      print('Error getting pending bookings count: $e');
      return 0;
    }
  }
}