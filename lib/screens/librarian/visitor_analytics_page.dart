import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionLabel({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}

// ─── Visitor Analytics Page ───────────────────────────────────────────────────

class VisitorAnalyticsPage extends StatefulWidget {
  const VisitorAnalyticsPage({super.key});

  @override
  State<VisitorAnalyticsPage> createState() => _VisitorAnalyticsPageState();
}

class _VisitorAnalyticsPageState extends State<VisitorAnalyticsPage> {
  Map<String, int>? _daily;
  Map<int, int>?   _hourly;
  bool _loading    = true;
  String? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadDaily();
  }

  Future<void> _loadDaily() async {
    setState(() => _loading = true);
    final data = await context.read<AppProvider>().fetchDailyVisitors(days: 30);
    final mapped = <String, int>{
      for (final item in data)
        (item['date'] as String): (item['count'] as int? ?? 0),
    };
    if (mounted) setState(() { _daily = mapped; _loading = false; });
  }

  Future<void> _loadHourly(String dayKey) async {
    final parts = dayKey.split('-');
    final date  = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    setState(() { _selectedDay = dayKey; _loading = true; });
    final data = await context.read<AppProvider>().fetchHourlyVisitors(date);
    final mapped = <int, int>{
      for (final item in data)
        (item['hour'] as int): (item['count'] as int? ?? 0),
    };
    if (mounted) setState(() { _hourly = mapped; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.visitorAnalytics),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _loadDaily();
              setState(() { _hourly = null; _selectedDay = null; });
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _daily == null || _daily!.isEmpty
              ? Center(child: Text(s.noAnalyticsData,
                  style: const TextStyle(color: Colors.grey)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _SectionLabel(
                        label: s.visitorsPerDay,
                        icon: Icons.calendar_today_outlined,
                        color: AppColors.teal),
                    const SizedBox(height: 10),
                    _DailyBarChart(
                      data: _daily!,
                      selectedKey: _selectedDay,
                      onDayTap: _loadHourly,
                    ),
                    const SizedBox(height: 20),
                    if (_hourly != null) ...[
                      _SectionLabel(
                          label: '${s.visitorsPerHour} – $_selectedDay',
                          icon: Icons.access_time_rounded,
                          color: AppColors.purple),
                      const SizedBox(height: 10),
                      _HourlyBarChart(data: _hourly!),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.teal.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.touch_app_outlined,
                                size: 16, color: AppColors.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(s.selectDayForHours,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.teal)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }
}

// ─── Daily bar chart ──────────────────────────────────────────────────────────

class _DailyBarChart extends StatelessWidget {
  final Map<String, int> data;
  final String? selectedKey;
  final ValueChanged<String> onDayTap;
  const _DailyBarChart(
      {required this.data, required this.selectedKey, required this.onDayTap});

  @override
  Widget build(BuildContext context) {
    final sorted = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxVal = sorted.isEmpty
        ? 1
        : sorted.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) {
      return Center(
          child: Text(S.of(context).noAnalyticsData,
              style: const TextStyle(color: Colors.grey)));
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final e       = sorted[i];
                final ratio   = e.value / maxVal;
                final isSelected = e.key == selectedKey;
                final parts   = e.key.split('-');
                final dayLabel = '${parts[2]}/${parts[1]}';
                final barColor = isSelected ? AppColors.accent : AppColors.teal;

                return GestureDetector(
                  onTap: () => onDayTap(e.key),
                  child: SizedBox(
                    width: 38,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${e.value}',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: barColor)),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 28,
                          height: (ratio * 90).clamp(4.0, 90.0),
                          decoration: BoxDecoration(
                            color: barColor.withOpacity(isSelected ? 1 : 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(dayLabel,
                            style: TextStyle(
                                fontSize: 8,
                                color: isSelected
                                    ? AppColors.accent
                                    : Colors.grey.shade500),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hourly bar chart ─────────────────────────────────────────────────────────

class _HourlyBarChart extends StatelessWidget {
  final Map<int, int> data;
  const _HourlyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.values.isEmpty
        ? 1
        : data.values.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) {
      return Center(
          child: Text(S.of(context).noAnalyticsData,
              style: const TextStyle(color: Colors.grey)));
    }

    final hours = List.generate(24, (i) => i)
        .where((h) => data.containsKey(h))
        .toList();

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: hours.map((h) {
          final val   = data[h] ?? 0;
          final ratio = val / maxVal;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    '${h.toString().padLeft(2, '0')}:00',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 22,
                      backgroundColor: AppColors.purple.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.purple),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  child: Text(
                    '$val',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
