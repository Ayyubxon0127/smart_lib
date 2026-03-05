import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app  = context.watch<AppProvider>();
    final user = app.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.accent.withOpacity(0.2),
                      child: Text(user?.avatar ?? '👤', style: const TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          Text(user?.email ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, children: [
                            StatusBadge(label: app.role == 'librarian' ? 'Kutubxonachi' : 'Talaba', color: AppColors.accent),
                            if (user?.degree != null)
                              StatusBadge(label: user!.degree == 'magistr' ? '🏅 Magistr' : '🎓 Bakalavr', color: AppColors.purple),
                            if (user?.group != null)
                              StatusBadge(label: user!.group!, color: AppColors.blue),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                if (user?.direction != null || user?.bio != null) ...[
                  const Divider(height: 20),
                  if (user?.direction != null)
                    Row(children: [
                      const Icon(Icons.school_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(child: Text(user!.direction!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
                    ]),
                  if (user?.bio != null) ...[
                    const SizedBox(height: 4),
                    Text('"${user!.bio}"', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                  ],
                ],
                const SizedBox(height: 14),
                AccentButton(
                  label: 'Profilni tahrirlash',
                  icon: Icons.edit_outlined,
                  onTap: () => showModalBottomSheet(
                    context: context, isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const _EditProfileSheet(),
                  ),
                ),
              ],
            ),
          ),

          // Appearance
          const SectionTitle(label: "Ko'rinish", icon: Icons.palette_outlined),
          AppCard(
            child: Column(children: [
              Row(children: [
                Icon(app.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(child: Text(app.isDark ? "Qorong'u rejim" : "Yorug' rejim")),
                Switch(value: app.isDark, onChanged: (_) => app.toggleDark(), activeColor: AppColors.accent),
              ]),
              const Divider(),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Align(alignment: Alignment.centerLeft, child: Text('Til', style: TextStyle(fontWeight: FontWeight.w600))),
              ),
              Row(children: [
                _LangBtn(code: 'uz', label: "O'zbek 🇺🇿"),
                const SizedBox(width: 8),
                _LangBtn(code: 'ru', label: 'Русский 🇷🇺'),
                const SizedBox(width: 8),
                _LangBtn(code: 'en', label: 'English 🇬🇧'),
              ]),
            ]),
          ),

          // Support
          const SectionTitle(label: "Qo'llab-quvvatlash", icon: Icons.support_agent_outlined),
          AppCard(
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: const Color(0xFF29B6F6).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.send_rounded, color: Color(0xFF29B6F6), size: 20),
              ),
              const SizedBox(width: 14),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Telegram', style: TextStyle(fontWeight: FontWeight.w700)),
                Text('@Ayyubxon_Ashiraliyev', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ])),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF29B6F6), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('Yozish', style: TextStyle(fontSize: 12)),
              ),
            ]),
          ),

          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.read<AppProvider>().logout(),
            icon: const Icon(Icons.logout_rounded, color: AppColors.red),
            label: const Text('Akkauntdan chiqish', style: TextStyle(color: AppColors.red)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.red.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String code, label;
  const _LangBtn({required this.code, required this.label});

  @override
  Widget build(BuildContext context) {
    final app    = context.watch<AppProvider>();
    final active = app.lang == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => app.setLang(code),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? AppColors.accent : Theme.of(context).dividerColor),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: active ? Colors.black : Colors.grey)),
        ),
      ),
    );
  }
}

// ── Edit Profile Sheet ──
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _groupCtrl = TextEditingController();
  final _bioCtrl   = TextEditingController();
  String _degree   = 'bakalavr';
  String _faculty  = '';
  String _direction= '';
  String _avatar   = '👨‍🎓';
  bool   _saving   = false;

  final _avatars = ['👨‍🎓','👩‍🎓','👨‍💻','👩‍💻','👨‍🔬','👩‍🔬','🧑‍💼','👨‍🏫','👩‍🏫','🧑‍🎓'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AppProvider>().currentUser;
    if (user != null) {
      _nameCtrl.text  = user.name;
      _phoneCtrl.text = user.phone;
      _groupCtrl.text = user.group ?? '';
      _bioCtrl.text   = user.bio ?? '';
      _degree         = user.degree ?? 'bakalavr';
      _faculty        = user.faculty ?? '';
      _direction      = user.direction ?? '';
      _avatar         = user.avatar ?? '👨‍🎓';
    }
  }

  @override
  Widget build(BuildContext context) {
    final app       = context.watch<AppProvider>();
    final isStudent = app.role == 'student';
    final selFaculty = kFacultyDirections[_faculty];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              const Text('Profilni tahrirlash', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                // Avatar
                SizedBox(
                  height: 54,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _avatars.map((av) => GestureDetector(
                      onTap: () => setState(() => _avatar = av),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: _avatar == av ? AppColors.accent : Colors.grey.shade300, width: 2),
                          borderRadius: BorderRadius.circular(12),
                          color: _avatar == av ? AppColors.accent.withOpacity(0.1) : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(av, style: const TextStyle(fontSize: 24)),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                AppTextField(hint: "To'liq ism *", controller: _nameCtrl, prefix: const Icon(Icons.person_outline, size: 18)),
                const SizedBox(height: 10),
                AppTextField(hint: 'Telefon', controller: _phoneCtrl, keyboardType: TextInputType.phone, prefix: const Icon(Icons.phone_outlined, size: 18)),
                const SizedBox(height: 10),

                if (isStudent) ...[
                  AppTextField(hint: 'Guruh (CS-21)', controller: _groupCtrl, prefix: const Icon(Icons.group_outlined, size: 18)),
                  const SizedBox(height: 16),

                  // Degree
                  const Text("Ta'lim darajasi", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _DegreeBtn(label: '🎓 Bakalavr', value: 'bakalavr', group: _degree,
                      onTap: () => setState(() { _degree = 'bakalavr'; _faculty = ''; _direction = ''; })),
                    const SizedBox(width: 10),
                    _DegreeBtn(label: '🏅 Magistr', value: 'magistr', group: _degree,
                      onTap: () => setState(() { _degree = 'magistr'; _faculty = 'Magistratura'; _direction = ''; })),
                  ]),
                  const SizedBox(height: 16),

                  // Bakalavr
                  if (_degree == 'bakalavr') ...[
                    const Text('Fakultet', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ...kFacultyNames.map((f) => GestureDetector(
                      onTap: () => setState(() { _faculty = f; _direction = ''; }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _faculty == f ? AppColors.accent.withOpacity(0.1) : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _faculty == f ? AppColors.accent : Theme.of(context).dividerColor.withOpacity(0.5)),
                        ),
                        child: Text(f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: _faculty == f ? AppColors.accent : null)),
                      ),
                    )),
                    if (selFaculty != null) ...[
                      const SizedBox(height: 8),
                      const Text("Yo'nalish", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: selFaculty.map((d) => GestureDetector(
                        onTap: () => setState(() => _direction = d),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _direction == d ? AppColors.accent : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _direction == d ? AppColors.accent : Theme.of(context).dividerColor.withOpacity(0.5)),
                          ),
                          child: Text(d, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: _direction == d ? Colors.black : null)),
                        ),
                      )).toList()),
                      const SizedBox(height: 12),
                    ],
                  ],

                  // Magistr
                  if (_degree == 'magistr') ...[
                    const Text("Magistratura yo'nalishi", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ...kMagistrDirections.asMap().entries.map((e) => GestureDetector(
                      onTap: () => setState(() => _direction = e.value),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: _direction == e.value ? AppColors.accent.withOpacity(0.1) : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: _direction == e.value ? AppColors.accent : Theme.of(context).dividerColor.withOpacity(0.5)),
                        ),
                        child: Row(children: [
                          Text('${e.key + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: _direction == e.value ? AppColors.accent : null))),
                          if (_direction == e.value) const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 16),
                        ]),
                      ),
                    )),
                    const SizedBox(height: 8),
                  ],
                ],

                AppTextField(hint: "O'zingiz haqingizda...", controller: _bioCtrl, maxLines: 3),
                const SizedBox(height: 20),
                AccentButton(
                  label: 'Saqlash',
                  icon: Icons.check_rounded,
                  loading: _saving,
                  onTap: () async {
                    if (_nameCtrl.text.trim().isEmpty) return;
                    setState(() => _saving = true);
                    await context.read<AppProvider>().updateProfile({
                      'name': _nameCtrl.text.trim(),
                      'phone': _phoneCtrl.text.trim(),
                      'group': _groupCtrl.text.trim(),
                      'bio': _bioCtrl.text.trim(),
                      'avatar': _avatar,
                      'degree': _degree,
                      'faculty': _faculty,
                      'direction': _direction,
                    });
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DegreeBtn extends StatelessWidget {
  final String label, value, group;
  final VoidCallback onTap;
  const _DegreeBtn({required this.label, required this.value, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = value == group;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? AppColors.accent : Theme.of(context).dividerColor),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: active ? Colors.black : null)),
        ),
      ),
    );
  }
}
