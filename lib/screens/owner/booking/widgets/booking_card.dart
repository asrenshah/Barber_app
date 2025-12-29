// lib/screens/owner/booking/widgets/booking_card.dart
import 'package:flutter/material.dart';
import 'package:barber_app/models/booking_model.dart';
import 'package:barber_app/screens/owner/booking/widgets/booking_action_buttons.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onUpdate;
  final bool isHistory;

  const BookingCard({
    super.key,
    required this.booking,
    this.onUpdate,
    this.isHistory = false,
  });

  // Payment badge widget
  Widget _buildPaymentBadge() {
    final isPaid = booking.isPaid;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid 
            ? Colors.green.withOpacity(isHistory ? 0.1 : 0.15)
            : Colors.orange.withOpacity(isHistory ? 0.1 : 0.15),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: isHistory ? 1 : 2,
      color: isHistory ? Colors.grey[50] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// CUSTOMER + TIME
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.customerName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isHistory ? Colors.grey[700] : Colors.black,
                    ),
                  ),
                ),
                Text(
                  booking.displayTime,
                  style: TextStyle(
                    fontSize: 14,
                    color: isHistory ? Colors.grey[600] : Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            /// SERVICE NAME
            Text(
              booking.serviceName,
              style: TextStyle(
                fontSize: 14,
                color: isHistory ? Colors.grey[600] : Colors.black87,
              ),
            ),

            const SizedBox(height: 6),

            /// PRICE + STATUS + PAYMENT BADGE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Price
                Text(
                  'RM ${booking.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isHistory ? Colors.grey[700] : Colors.black,
                  ),
                ),
                
                // Status Badge + Payment Badge
                Row(
                  children: [
                    _StatusBadge(status: booking.status, isHistory: isHistory),
                    const SizedBox(width: 8),
                    _buildPaymentBadge(),
                  ],
                ),
              ],
            ),

            /// Barber info (jika ada)
            if (booking.barberName != null && booking.barberName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Barber: ${booking.barberName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isHistory ? Colors.grey[500] : Colors.blueGrey,
                  ),
                ),
              ),

            /// ACTION BUTTONS (ONLY PENDING & NOT HISTORY)
            if (booking.status == BookingStatus.pending && !isHistory) ...[
              const SizedBox(height: 12),
              BookingActionButtons(
                booking: booking,
                onUpdate: onUpdate,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Status Badge
class _StatusBadge extends StatelessWidget {
  final BookingStatus status;
  final bool isHistory;

  const _StatusBadge({required this.status, this.isHistory = false});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case BookingStatus.confirmed:
        color = isHistory ? Colors.blue[300]! : Colors.blue;
        text = 'Confirmed';
        break;
      case BookingStatus.completed:
        color = isHistory ? Colors.green[300]! : Colors.green;
        text = 'Completed';
        break;
      case BookingStatus.cancelled:
        color = isHistory ? Colors.red[300]! : Colors.red;
        text = 'Cancelled';
        break;
      case BookingStatus.pending:
      default:
        color = isHistory ? Colors.orange[300]! : Colors.orange;
        text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isHistory ? 0.1 : 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}