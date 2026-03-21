import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/room_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

// ─── Block time slot form ─────────────────────────────────────────────────────

class BlockFormSheet extends StatefulWidget {
  final RoomModel room;
  const BlockFormSheet({super.key, required this.room});

  @override
  State<BlockFormSheet> createState() => _BlockFormSheetState();
}

class _BlockFormSheetState extends State<BlockFormSheet> {
  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end   = const TimeOfDay(hour: 17, minute: 0);
  final _reasonCtrl = TextEditingController();
  bool _saving   = false;
  bool _fullDay  = false;
  List<RoomBlockModel>? _blocks;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

  String get _startStr => _fullDay ? widget.room.openTime : _fmt(_start);
  String get _endStr   => _fullDay ? widget.room.closeTime : _fmt(_end);

  @override
  void initState() {
    super.initState();
    _loadBlocks();
  }

  @override
  void dispose() { _reasonCtrl.dispose(); super.dispose(); }

  Future<void> _loadBlocks() async {
    final blocks = await context.read<AppProvider>().fetchRoomBlocks(widget.room.id);
    if (mounted) setState(() => _blocks = blocks);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (t != null) setState(() { if (isStart) _start = t; else _end = t; });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final s   = S.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(children: [
                Expanded(child: Text('${s.blockTime}: ${widget.room.name}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10)),
                            child: Row(children: [
                              const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.accent),
                              const SizedBox(width: 10),
                              Text('${_date.day.toString().padLeft(2,'0')}.${_date.month.toString().padLeft(2,'0')}.${_date.year}',
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => setState(() {
                            _fullDay = !_fullDay;
                            if (_fullDay) {
                              _reasonCtrl.text = s.holidayReason;
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _fullDay
                                  ? AppColors.red.withOpacity(0.1)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _fullDay
                                    ? AppColors.red.withOpacity(0.4)
                                    : Theme.of(context).dividerColor.withOpacity(0.5),
                              ),
                            ),
                            child: Row(children: [
                              Icon(
                                _fullDay ? Icons.event_busy_rounded : Icons.event_available_outlined,
                                size: 18,
                                color: _fullDay ? AppColors.red : Colors.grey,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.fullDayBlock,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: _fullDay ? AppColors.red : null)),
                                    Text(
                                      '${widget.room.openTime} – ${widget.room.closeTime}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _fullDay,
                                onChanged: (v) => setState(() {
                                  _fullDay = v;
                                  if (v) _reasonCtrl.text = s.holidayReason;
                                }),
                                activeColor: AppColors.red,
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (!_fullDay)
                          Row(children: [
                            Expanded(child: InkWell(
                              onTap: () => _pickTime(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10)),
                                child: Row(children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: AppColors.accent),
                                  const SizedBox(width: 8),
                                  Text(_fmt(_start), style: const TextStyle(fontWeight: FontWeight.w700)),
                                ]),
                              ),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: InkWell(
                              onTap: () => _pickTime(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10)),
                                child: Row(children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: AppColors.orange),
                                  const SizedBox(width: 8),
                                  Text(_fmt(_end), style: const TextStyle(fontWeight: FontWeight.w700)),
                                ]),
                              ),
                            )),
                          ]),
                        if (!_fullDay) const SizedBox(height: 10),
                        AppTextField(hint: s.blockReasonHint, controller: _reasonCtrl),
                        const SizedBox(height: 12),
                        AccentButton(
                          label: s.blockTime,
                          icon: Icons.block_outlined,
                          loading: _saving,
                          onTap: () async {
                            if (_reasonCtrl.text.trim().isEmpty) return;
                            setState(() => _saving = true);
                            final err = await app.addRoomBlock(
                                widget.room.id, _date, _startStr, _endStr,
                                _reasonCtrl.text.trim());
                            if (err != null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('⚠️ $err'),
                                        backgroundColor: AppColors.orange));
                                setState(() => _saving = false);
                              }
                              return;
                            }
                            _reasonCtrl.clear();
                            setState(() => _fullDay = false);
                            await _loadBlocks();
                            if (mounted) setState(() => _saving = false);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(s.blockedTimes.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  if (_blocks == null)
                    const Center(child: CircularProgressIndicator())
                  else if (_blocks!.isEmpty)
                    Text(s.noBlocks, style: const TextStyle(color: Colors.grey))
                  else
                    ..._blocks!.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        borderColor: AppColors.red.withOpacity(0.3),
                        child: Row(
                          children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${b.date.day.toString().padLeft(2,'0')}.${b.date.month.toString().padLeft(2,'0')}.${b.date.year}  ${b.startTime} – ${b.endTime}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                const SizedBox(height: 3),
                                Text(b.reason, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            )),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                              onPressed: () async {
                                await app.deleteRoomBlock(b.id);
                                await _loadBlocks();
                              },
                            ),
                          ],
                        ),
                      ),
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
