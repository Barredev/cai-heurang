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
        ...recent.map((log) => _HistoryItem(
          log: log,
          onDelete: () async {
            final bool removed;
            if (log is WaterLogModel) {
              removed = await ref.read(dailyWaterProvider.notifier).deleteLog(log.id);
            } else if (log is SweetLogModel) {
              removed = await ref.read(sweetProvider.notifier).deleteLog(log.id);
            } else {
              removed = false;
            }
            if (removed && context.mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Catatan dihapus'),
                    duration: Duration(seconds: 2),
                  ),
                );
            }
          },
        )),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final dynamic log;
  final VoidCallback onDelete;
  const _HistoryItem({required this.log, required this.onDelete});

  String _sweetLabel(SweetLogModel sweet) {
    final emoji = AppConstants.drinkEmoji[sweet.drinkType] ?? '🫗';
    final customName = sweet.drinkName?.trim();
    final name = (sweet.drinkType == 'other' &&
            customName != null &&
            customName.isNotEmpty)
        ? customName
        : (AppConstants.drinkLabel[sweet.drinkType] ?? 'Minuman');
    return '$emoji $name';
  }

  @override
  Widget build(BuildContext context) {
    final isWater = log is WaterLogModel;
    final time    = DateFormat('HH:mm').format(DateTime.parse(log.timestamp));
    final label   = isWater
        ? '1 Gelas Air 💧'
        : (log is SweetLogModel ? _sweetLabel(log) : '');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        const Text('⏰', style: TextStyle(fontSize: 14)),
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
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.close_rounded, size: 18),
          color: AppColors.textHint,
          tooltip: 'Hapus catatan',
          visualDensity: VisualDensity.compact,
        ),
      ]),
    );
  }
}