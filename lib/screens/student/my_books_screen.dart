import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/reservation_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';

class MyBooksScreen extends StatelessWidget {
  const MyBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app          = context.watch<AppProvider>();
    final reservations = app.reservations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mening kitoblarim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => app.fetchReservations(),
          ),
        ],
      ),
      body: reservations.isEmpty
          ? const Center(
              child: Text("Hali bron qilingan kitob yo'q",
                  style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reservations.length,
              itemBuilder: (_, i) =>
                  _ReservationCard(reservation: reservations[i]),
            ),
    );
  }
}

class _ReservationCard extends StatefulWidget {
  final ReservationModel reservation;
  const _ReservationCard({required this.reservation});

  @override
  State<_ReservationCard> createState() => _ReservationCardState();
}

class _ReservationCardState extends State<_ReservationCard> {
  bool _loading = false;

  (String, Color) _statusInfo(String status) => switch (status) {
        'pending_confirm'  => ('Tasdiq kutilmoqda', AppColors.orange),
        'active'           => ('Faol', AppColors.green),
        'return_requested' => ("Qaytarish so'rovi", AppColors.blue),
        'returned'         => ('Qaytarilgan', Colors.grey),
        _                  => ("Noma'lum", Colors.grey),
      };

  @override
  Widget build(BuildContext context) {
    final app       = context.watch<AppProvider>();
    final res       = widget.reservation;
    final isOverdue = res.isOverdue;
    final bookList  = app.books.where((b) => b.id == res.bookId);
    final bookTitle = bookList.isNotEmpty ? bookList.first.title : 'Kitob';
    final bookEmoji = bookList.isNotEmpty ? bookList.first.coverEmoji : '📖';
    final bookImg   = bookList.isNotEmpty ? bookList.first.imageUrl : null;
    final info      = _statusInfo(res.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        borderColor: isOverdue ? AppColors.red.withOpacity(0.5) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BookCover(imageUrl: bookImg, emoji: bookEmoji, width: 44, height: 58),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bookTitle,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          maxLines: 2),
                      const SizedBox(height: 6),
                      StatusBadge(label: info.$1, color: info.$2),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                    '${res.reserveDate.day}.${res.reserveDate.month}.${res.reserveDate.year}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(width: 12),
                Icon(Icons.timer_outlined,
                    size: 12,
                    color: isOverdue ? AppColors.red : Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  isOverdue
                      ? '${res.daysLeft.abs()} kun kechikdi'
                      : '${res.daysLeft} kun qoldi',
                  style: TextStyle(
                      fontSize: 11,
                      color: isOverdue ? AppColors.red : Colors.grey.shade500,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (res.status == 'active') ...[
              const SizedBox(height: 10),
              AccentButton(
                label: "Qaytarish so'rovi",
                icon: Icons.assignment_return_outlined,
                loading: _loading,
                onTap: () async {
                  setState(() => _loading = true);
                  await app.updateReservationStatus(res.id, 'return_requested');
                  if (mounted) {
                    setState(() => _loading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Qaytarish so'rovi yuborildi")),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}