import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum BookingStatus {
  pending,
  confirmed,
  completed,
  cancelled,
}

class Booking {
  final String id;
  final String shopId;
  final String customerId;
  final String customerName;
  final String serviceName;
  final double price;
  final DateTime startAt;
  final BookingStatus status;
  final bool isPaid;
  final bool isWalkIn;
  final DateTime? createdAt;
  final String? barberName;

  Booking({
    required this.id,
    required this.shopId,
    required this.customerId,
    required this.customerName,
    required this.serviceName,
    required this.price,
    required this.startAt,
    required this.status,
    required this.isPaid,
    required this.isWalkIn,
    this.createdAt,
    this.barberName,
  });

  /// 🔥 INI YANG KURANG SEBELUM INI
  factory Booking.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return Booking(
      id: doc.id,
      shopId: data['shopId'],
      customerId: data['customerId'],
      customerName: data['customerName'],
      serviceName: data['serviceName'],
      price: (data['price'] as num).toDouble(),
      startAt: (data['startAt'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      isPaid: data['isPaid'] ?? false,
      isWalkIn: data['isWalkIn'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  String get displayTime => DateFormat('h:mm a').format(startAt);
  String get displayDate => DateFormat('dd MMM yyyy').format(startAt);
}
