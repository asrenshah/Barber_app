// lib/screens/owner/booking/widgets/booking_action_buttons.dart

import 'package:flutter/material.dart';
import 'package:barber_app/models/booking_model.dart';
import 'package:barber_app/services/booking_service.dart';

class BookingActionButtons extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onUpdate;

  const BookingActionButtons({
    super.key,
    required this.booking,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    // Hanya show button jika status pending
    if (booking.status != BookingStatus.pending) {
      return const SizedBox();
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () async {
              await BookingService.updateStatus(
                booking.id,
                BookingStatus.confirmed,
              );
              onUpdate?.call();
            },
            child: const Text('Confirm'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              await BookingService.updateStatus(
                booking.id,
                BookingStatus.cancelled,
              );
              onUpdate?.call();
            },
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }
}
