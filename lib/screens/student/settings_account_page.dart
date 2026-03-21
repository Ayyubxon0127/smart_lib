import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/app_provider.dart';
import '../../constants.dart';
import '../../l10n.dart';
import '../login_screen.dart';
import 'settings_widgets.dart';

// ── 6. Account Page ───────────────────────────────────────────────────────────

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.account)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          SettingsCard(tiles: [
            NavTile(
              icon: Icons.lock_outline_rounded,
              iconColor: AppColors.orange,
              title: s.changePassword,
              subtitle: s.lang == 'uz'
                  ? 'Eski va yangi parolni kiriting'
                  : s.lang == 'en'
                      ? 'Enter old and new password'
                      : 'Введите старый и новый пароль',
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const _ChangePasswordSheet(),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          const LogoutButton(),
        ],
      ),
    );
  }
}

// ── Change Password Sheet ─────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _oldCtrl     = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _oldFocus     = FocusNode();
  final _newFocus     = FocusNode();
  final _confirmFocus = FocusNode();

  bool _showOld     = false;
  bool _showNew     = false;
  bool _showConfirm = false;
  bool _loading     = false;

  String? _oldError;
  String? _newError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _oldFocus.addListener(() => setState(() {}));
    _newFocus.addListener(() => setState(() {}));
    _confirmFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _oldFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  bool _validate(S s) {
    final old     = _oldCtrl.text;
    final newP    = _newCtrl.text;
    final confirm = _confirmCtrl.text;
    setState(() {
      _oldError     = old.isEmpty     ? (s.lang == 'uz' ? 'Eski parolni kiriting' : s.lang == 'en' ? 'Enter old password' : 'Введите старый пароль') : null;
      _newError     = newP.length < 6 ? s.passwordTooShort : null;
      _confirmError = newP != confirm  ? s.passwordMismatch : null;
    });
    return _oldError == null && _newError == null && _confirmError == null;
  }

  Future<void> _submit() async {
    final s = S.read(context);
    if (!_validate(s)) return;
    setState(() => _loading = true);

    final user  = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    try {
      // 1. Re-authenticate with old password
      final cred = EmailAuthProvider.credential(
        email:    email,
        password: _oldCtrl.text,
      );
      await user!.reauthenticateWithCredential(cred);

      // 2. Update to new password
      await user.updatePassword(_newCtrl.text);

      if (mounted) {
        Navigator.pop(context);
        showSnack(
          context,
          s.lang == 'uz' ? 'Parol muvaffaqiyatli o\'zgartirildi ✅'
              : s.lang == 'en' ? 'Password changed successfully ✅'
              : 'Пароль успешно изменён ✅',
          AppColors.green,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      final msg = _friendlyError(e.code, s);
      setState(() => _oldError = msg);
    } catch (_) {
      setState(() {
        _loading  = false;
        _oldError = s.errorOccurred;
      });
    }
  }

  String _friendlyError(String code, S s) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return s.lang == 'uz' ? 'Eski parol noto\'g\'ri' : s.lang == 'en' ? 'Old password is incorrect' : 'Старый пароль неверен';
      case 'weak-password':
        return s.passwordTooShort;
      case 'too-many-requests':
        return s.tooManyRequests;
      default:
        return s.errorOccurred;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s      = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF0B1426) : const Color(0xFFF4F6FB);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title row
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_outline_rounded, color: AppColors.orange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      s.changePassword,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Old password
                _PasswordField(
                  controller: _oldCtrl,
                  focusNode:  _oldFocus,
                  label: s.lang == 'uz' ? 'Eski parol' : s.lang == 'en' ? 'Old password' : 'Старый пароль',
                  show:  _showOld,
                  error: _oldError,
                  onToggle: () => setState(() => _showOld = !_showOld),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                // Divider hint
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    s.lang == 'uz' ? 'Yangi parol (kamida 6 belgi)'
                        : s.lang == 'en' ? 'New password (min 6 characters)'
                        : 'Новый пароль (мин. 6 символов)',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
                ),
                // New password
                _PasswordField(
                  controller: _newCtrl,
                  focusNode:  _newFocus,
                  label: s.lang == 'uz' ? 'Yangi parol' : s.lang == 'en' ? 'New password' : 'Новый пароль',
                  show:  _showNew,
                  error: _newError,
                  onToggle: () => setState(() => _showNew = !_showNew),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                // Confirm password
                _PasswordField(
                  controller: _confirmCtrl,
                  focusNode:  _confirmFocus,
                  label: s.lang == 'uz' ? 'Yangi parolni tasdiqlang' : s.lang == 'en' ? 'Confirm new password' : 'Подтвердите новый пароль',
                  show:  _showConfirm,
                  error: _confirmError,
                  onToggle: () => setState(() => _showConfirm = !_showConfirm),
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                // Save button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(colors: [Color(0xFF3BA9FF), Color(0xFF8B5CF6)]),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    icon: _loading
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 18),
                    label: Text(
                      s.lang == 'uz' ? 'Parolni o\'zgartirish'
                          : s.lang == 'en' ? 'Change password'
                          : 'Изменить пароль',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Password input field ──────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final bool show;
  final String? error;
  final VoidCallback onToggle;
  final bool isDark;

  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.show,
    required this.error,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8F9FA),
        border: Border.all(
          color: error != null
              ? AppColors.red
              : focused
                  ? AppColors.accent
                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          width: focused ? 1.4 : 1,
        ),
        boxShadow: focused
            ? [BoxShadow(color: AppColors.accent.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: TextField(
        controller:    controller,
        focusNode:     focusNode,
        obscureText:   !show,
        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827)),
        decoration: InputDecoration(
          labelText:   label,
          errorText:   error,
          prefixIcon:  Icon(Icons.lock_outline, size: 18,
              color: error != null ? AppColors.red : (focused ? AppColors.accent : Colors.grey)),
          suffixIcon: IconButton(
            icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18, color: Colors.grey),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}

// ── Logout Button ─────────────────────────────────────────────────────────────

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              title: Text(s.logout,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              content: Text(
                s.lang == 'uz'
                    ? 'Akkauntdan chiqishni tasdiqlaysizmi?'
                    : s.lang == 'en'
                        ? 'Are you sure you want to sign out?'
                        : 'Вы уверены, что хотите выйти?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(s.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.red),
                  child: Text(s.logout,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
          if (confirmed == true && context.mounted) {
            await context.read<AppProvider>().logout();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            }
          }
        },
        icon: const Icon(Icons.logout_rounded, color: AppColors.red, size: 18),
        label: Text(s.logout,
            style: const TextStyle(
                color: AppColors.red, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.red.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ── Edit Profile Sheet ────────────────────────────────────────────────────────

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});
  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _photoUrlCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();

  String _degree = 'bakalavr';
  String _faculty = '';
  String _direction = '';
  String _avatar = '👨‍🎓';
  String? _photoUrl;

  String? _nameError;
  String? _phoneError;
  bool _saving = false;

  final _avatars = const ['👨‍🎓', '👩‍🎓', '👨‍💻', '👩‍💻', '👨‍🔬', '👩‍🔬', '🧑‍💼', '👨‍🏫', '👩‍🏫', '🧑‍🎓'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AppProvider>().currentUser;
    if (user != null) {
      _nameCtrl.text = user.name;
      final rawPhone = user.phone.trim();
      _phoneCtrl.text = rawPhone.startsWith('+998') ? rawPhone.substring(4) : rawPhone;
      _bioCtrl.text = user.bio ?? '';
      _degree = user.degree ?? 'bakalavr';
      _faculty = user.faculty ?? '';
      _direction = user.direction ?? '';
      _avatar = user.avatar ?? '👨‍🎓';
      _photoUrl = user.photoUrl;
      _photoUrlCtrl.text = user.photoUrl ?? '';
    }
    _nameFocus.addListener(() => setState(() {}));
    _phoneFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _photoUrlCtrl.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  bool _isValidUrl(String input) {
    final u = Uri.tryParse(input.trim());
    return u != null && (u.scheme == 'http' || u.scheme == 'https') && (u.host.isNotEmpty);
  }

  Future<void> _openAvatarUrlDialog() async {
    final s = S.read(context);
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xFF0F1A2D) : const Color(0xFFF4F6FA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.lang == 'uz' ? 'Avatar URL' : s.lang == 'en' ? 'Avatar URL' : 'URL аватара',
        ),
        content: TextField(
          controller: _photoUrlCtrl,
          decoration: const InputDecoration(
            hintText: 'https://...'
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _photoUrlCtrl.text.trim()),
            child: Text(s.save),
          ),
        ],
      ),
    );
    if (res == null) return;
    if (res.isEmpty) {
      setState(() => _photoUrl = null);
      return;
    }
    if (_isValidUrl(res)) {
      setState(() => _photoUrl = res);
    } else {
      if (!mounted) return;
      showSnack(context,
          s.lang == 'uz' ? 'URL noto\'g\'ri' : s.lang == 'en' ? 'Invalid URL' : 'Неверный URL',
          AppColors.red);
    }
  }

  List<String> _specializationOptions() {
    final list = <String>{
      'Kompyuter injiniringi',
      'Dasturiy injiniring',
      'Sun\'iy intellekt',
    };
    for (final v in kFacultyDirections.values) {
      list.addAll(v);
    }
    list.addAll(kMagistrDirections);
    return list.toList()..sort();
  }

  Future<void> _openSpecializationPicker() async {
    final s = S.read(context);
    final options = _specializationOptions();
    String query = '';
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final sheetIsDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(builder: (ctx, setSheet) {
          final filtered = options.where((e) => e.toLowerCase().contains(query.toLowerCase())).toList();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.7,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(width: 44, height: 4, decoration: BoxDecoration(color: sheetIsDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(99))),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        onChanged: (v) => setSheet(() => query = v),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: s.searchHint,
                          filled: true,
                          fillColor: sheetIsDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF0F2F5),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final item = filtered[i];
                          final isSel = item == _direction;
                          return ListTile(
                            title: Text(item),
                            trailing: isSel ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                            onTap: () => Navigator.pop(ctx, item),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
    if (selected != null) {
      setState(() {
        _direction = selected;
        if (_degree == 'bakalavr') {
          _faculty = kFacultyDirections.entries.firstWhere(
            (e) => e.value.contains(selected),
            orElse: () => const MapEntry('', <String>[]),
          ).key;
        } else {
          _faculty = 'Magistratura';
        }
      });
    }
  }

  bool _validate() {
    final name = _nameCtrl.text.trim();
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _nameError = name.isEmpty ? 'Ism majburiy' : null;
      _phoneError = digits.length < 9 ? 'Telefon raqam noto\'g\'ri' : null;
    });
    return _nameError == null && _phoneError == null;
  }

  Future<void> _saveProfile() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    final phoneDigits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    await context.read<AppProvider>().updateProfile({
      'name': _nameCtrl.text.trim(),
      'phone': '+998$phoneDigits',
      'bio': _bioCtrl.text.trim(),
      'avatar': _avatar,
      'photoUrl': _photoUrl,
      'degree': _degree,
      'faculty': _faculty,
      'direction': _direction,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1426) : const Color(0xFFF4F6FB);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              children: [
                Row(
                  children: [
                    Text(s.editProfileTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFE2E8F0)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Avatar', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 78,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ..._avatars.map((av) {
                              final active = _photoUrl == null && _avatar == av;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _avatar = av;
                                  _photoUrl = null;
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: active
                                        ? const LinearGradient(colors: [Color(0xFF3BA9FF), Color(0xFF8B5CF6)])
                                        : null,
                                    border: active ? null : Border.all(color: isDark ? Colors.white24 : Colors.black12),
                                    boxShadow: active
                                        ? [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.35), blurRadius: 16)]
                                        : null,
                                  ),
                                  child: CircleAvatar(radius: 28, backgroundColor: isDark ? const Color(0xFF111D33) : const Color(0xFFEEF2FF), child: Text(av, style: const TextStyle(fontSize: 24))),
                                ),
                              );
                            }),
                            GestureDetector(
                              onTap: _openAvatarUrlDialog,
                              child: Container(
                                width: 62,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF0F2F5),
                                  border: Border.all(color: isDark ? Colors.white30 : Colors.black12),
                                ),
                                child: _photoUrl != null && _isValidUrl(_photoUrl!)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.network(_photoUrl!, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.add_a_photo_outlined))),
                                      )
                                    : Icon(Icons.add, color: isDark ? Colors.white70 : Colors.black45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _glassInput(
                  label: s.fullName,
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  icon: Icons.person_outline,
                  error: _nameError,
                ),
                const SizedBox(height: 10),
                _glassInput(
                  label: s.phone,
                  controller: _phoneCtrl,
                  focusNode: _phoneFocus,
                  icon: Icons.phone_outlined,
                  prefixText: '+998 ',
                  keyboardType: TextInputType.phone,
                  error: _phoneError,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.14) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SegmentOption(
                          label: s.bakalavr,
                          icon: Icons.school_rounded,
                          active: _degree == 'bakalavr',
                          onTap: () => setState(() => _degree = 'bakalavr'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SegmentOption(
                          label: s.magistr,
                          icon: Icons.workspace_premium_rounded,
                          active: _degree == 'magistr',
                          onTap: () => setState(() => _degree = 'magistr'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _openSpecializationPicker,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.14) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded, size: 18, color: AppColors.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _direction.isEmpty ? 'Specialization tanlang' : _direction,
                            style: TextStyle(color: _direction.isEmpty ? Colors.grey : null),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _glassInput(
                  label: s.aboutYourself,
                  controller: _bioCtrl,
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                ),
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [Color(0xFF3BA9FF), Color(0xFF8B5CF6)]),
                  boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 8))],
                ),
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, color: Colors.white),
                  label: Text(s.save, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassInput({
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    required IconData icon,
    String? prefixText,
    TextInputType? keyboardType,
    String? error,
    int maxLines = 1,
  }) {
    final focused = focusNode?.hasFocus ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8F9FA),
        border: Border.all(color: error != null ? AppColors.red : (focused ? AppColors.accent : (isDark ? Colors.white12 : const Color(0xFFE2E8F0))), width: focused ? 1.4 : 1),
        boxShadow: focused
            ? [BoxShadow(color: AppColors.accent.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6))]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827)),
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          prefixIcon: Icon(icon, size: 18),
          prefixText: prefixText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}

class SegmentOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const SegmentOption({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: active ? const LinearGradient(colors: [Color(0xFF3BA9FF), Color(0xFF8B5CF6)]) : null,
          color: active ? null : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF0F2F5)),
          border: Border.all(color: active ? Colors.transparent : (isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: active ? Colors.white : (isDark ? Colors.white : const Color(0xFF374151))),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: active ? Colors.white : (isDark ? Colors.white : const Color(0xFF374151)), fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
