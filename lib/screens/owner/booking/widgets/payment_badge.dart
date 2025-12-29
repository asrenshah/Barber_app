// lib/screens/owner/booking/widgets/payment_badge.dart
import 'package:flutter/material.dart';
import '../../../../models/booking_model.dart';

class PaymentBadge extends StatelessWidget {
  final Booking booking;

  const PaymentBadge({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final isPaid = booking.isPaid;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid 
            ? Colors.green.withOpacity(0.15)
            : Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaid ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.pending,
            size: 14,
            color: isPaid ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isPaid ? 'PAID' : 'UNPAID',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isPaid ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}