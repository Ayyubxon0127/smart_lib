import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/room_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

// ── Xona qo'shish/tahrirlash formasi ─────────────────────────────────────────

class RoomFormSheet extends StatefulWidget {
  final RoomModel? room;
  const RoomFormSheet({super.key, this.room});

  @override
  State<RoomFormSheet> createState() => _RoomFormSheetState();
}

class _RoomFormSheetState extends State<RoomFormSheet> {
  final _nameCtrl = TextEditingController();
  final _capCtrl  = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<TextEditingController> _imageCtrlList = [];
  TimeOfDay _openTime  = const TimeOfDay(hour: 8,  minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 20, minute: 0);
  bool _saving = false;

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay _parseTime(String s) {
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  List<String> get _imageUrls =>
      _imageCtrlList.map((c) => c.text.trim()).where((u) => u.isNotEmpty).toList();

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      final r = widget.room!;
      _nameCtrl.text = r.name;
      _capCtrl.text  = '${r.capacity}';
      _descCtrl.text = r.description ?? '';
      _openTime  = _parseTime(r.openTime);
      _closeTime = _parseTime(r.closeTime);
      for (final url in r.imageUrls) {
        _imageCtrlList.add(TextEditingController(text: url));
      }
    } else {
      _capCtrl.text = '10';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _capCtrl.dispose(); _descCtrl.dispose();
    for (final c in _imageCtrlList) c.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isOpen) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isOpen ? _openTime : _closeTime,
    );
    if (t != null) setState(() { if (isOpen) _openTime = t; else _closeTime = t; });
  }

  @override
  Widget build(BuildContext context) {
    final app    = context.read<AppProvider>();
    final s      = S.read(context);
    final isEdit = widget.room != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(children: [
                Text(isEdit ? s.editRoom : s.addRoom,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            const Divider(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  AppTextField(hint: s.roomNameHint, controller: _nameCtrl,
                      prefix: const Icon(Icons.meeting_room_outlined, size: 18)),
                  const SizedBox(height: 10),
                  AppTextField(hint: s.capacityHint, controller: _capCtrl,
                      keyboardType: TextInputType.number,
                      prefix: const Icon(Icons.people_outline, size: 18)),
                  const SizedBox(height: 10),
                  AppTextField(hint: s.roomDescHint, controller: _descCtrl, maxLines: 2,
                      prefix: const Icon(Icons.info_outline, size: 18)),
                  const SizedBox(height: 14),

                  Row(children: [
                    const Icon(Icons.photo_library_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    const Text('Xona rasmlari (ixtiyoriy)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
                  ]),
                  const SizedBox(height: 8),

                  ...List.generate(_imageCtrlList.length, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_imageCtrlList[i].text.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8, top: 2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _imageCtrlList[i].text.trim(),
                                width: 44, height: 44, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 44, height: 44,
                                  color: AppColors.accent.withOpacity(0.1),
                                  child: const Icon(Icons.broken_image_outlined,
                                      color: AppColors.red, size: 20),
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: TextField(
                            controller: _imageCtrlList[i],
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Rasm URL ${i + 1}',
                              hintStyle: const TextStyle(fontSize: 12),
                              prefixIcon: const Icon(Icons.link_rounded, size: 18),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppColors.red, size: 20),
                          onPressed: () => setState(() {
                            _imageCtrlList[i].dispose();
                            _imageCtrlList.removeAt(i);
                          }),
                        ),
                      ],
                    ),
                  )),

                  GestureDetector(
                    onTap: () => setState(() => _imageCtrlList.add(TextEditingController())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.accent.withOpacity(0.35),
                            style: BorderStyle.solid),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 18, color: AppColors.accent),
                          SizedBox(width: 8),
                          Text('Rasm qo\'shish',
                              style: TextStyle(fontSize: 13, color: AppColors.accent,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(s.workingHours,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TimePickerTile(
                      label: s.openTime, time: _openTime,
                      color: AppColors.green, onTap: () => _pickTime(true),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: TimePickerTile(
                      label: s.closeTime, time: _closeTime,
                      color: AppColors.red, onTap: () => _pickTime(false),
                    )),
                  ]),
                  const SizedBox(height: 20),
                  AccentButton(
                    label: isEdit ? s.save : s.add,
                    icon: Icons.check_rounded,
                    loading: _saving,
                    onTap: () async {
                      if (_nameCtrl.text.trim().isEmpty) return;
                      setState(() => _saving = true);
                      final cap = int.tryParse(_capCtrl.text.trim()) ?? 1;
                      if (isEdit) {
                        await app.updateRoom(widget.room!.id, {
                          'name': _nameCtrl.text.trim(),
                          'capacity': cap,
                          'description': _descCtrl.text.trim().isEmpty
                              ? null : _descCtrl.text.trim(),
                          'openTime': _fmtTime(_openTime),
                          'closeTime': _fmtTime(_closeTime),
                          'imageUrls': _imageUrls,
                        });
                      } else {
                        await app.addRoom(RoomModel(
                          id: '', name: _nameCtrl.text.trim(), capacity: cap,
                          description: _descCtrl.text.trim().isEmpty
                              ? null : _descCtrl.text.trim(),
                          openTime: _fmtTime(_openTime),
                          closeTime: _fmtTime(_closeTime),
                          imageUrls: _imageUrls,
                        ));
                      }
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final Color color;
  final VoidCallback onTap;
  const TimePickerTile({super.key, required this.label, required this.time, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Icon(Icons.access_time_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            Text(
              '${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ]),
        ]),
      ),
    );
  }
}
