// lib/features/home/widgets/mini_history.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/water_log_model.dart';
import '../../../data/models/sweet_log_model.dart';
import '../../../shared/providers/app_providers.dart';

class MiniHistory extends ConsumerWidget {
  final String profileId;
  const MiniHistory({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterLogs = ref.watch(dailyWaterProvider).recentLogs;
    final sweetLogs = ref.watch(sweetProvider).todayLogs;

    // Gabungkan & ambil 3 terbaru
    final all = <dynamic>[...waterLogs, ...sweetLogs]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recent = all.take(3).toList();

    if (recent.isEmpty) {
      return Center(
        child: Text('Belum ada catatan hari ini~',
          style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Catatan terbaru',
          style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ...recent.map((log) => _HistoryItem(log: log)),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final dynamic log;
  const _HistoryItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final isWater = log is WaterLogModel;
    final time    = DateFormat('HH:mm').format(DateTime.parse(log.timestamp));
    final label   = isWater
        ? '1 Gelas Air 💧'
        : (log is SweetLogModel
            ? '${AppConstants.drinkEmoji[log.drinkType] ?? '🫗'} '
              '${AppConstants.drinkLabel[log.drinkType] ?? log.drinkName ?? 'Minuman'}'
            : '');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        Text('⏰', style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Text(time,
          style: const TextStyle(
            fontFamily: 'Nunito', fontWeight: FontWeight.w600,
            color: AppColors.textSecondary, fontSize: 13,
          )),
        const SizedBox(width: 8),
        const Text('·', style: TextStyle(color: AppColors.textHint)),
        const SizedBox(width: 8),
        Expanded(child: Text(label,
          style: const TextStyle(
            fontFamily: 'Nunito', fontWeight: FontWeight.w600,
            fontSize: 13,
          ))),
      ]),
    );
  }
}