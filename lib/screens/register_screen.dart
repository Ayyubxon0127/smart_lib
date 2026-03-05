import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../constants.dart';
import '../widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _pass2Ctrl   = TextEditingController();

  bool _obscure1     = true;
  bool _obscure2     = true;
  String? _errorMsg;

  String  _degree    = 'bakalavr';
  String? _faculty;
  String? _direction;
  String  _group     = '';

  final _groupCtrl   = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _pass2Ctrl.dispose(); _groupCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _errorMsg = null);

    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _errorMsg = "Barcha majburiy maydonlarni to'ldiring");
      return;
    }
    if (_passCtrl.text != _pass2Ctrl.text) {
      setState(() => _errorMsg = "Parollar mos kelmaydi");
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _errorMsg = "Parol kamida 6 ta belgidan iborat bo'lishi kerak");
      return;
    }

    final app = context.read<AppProvider>();
    final ok = await app.register(
      name:      _nameCtrl.text.trim(),
      email:     _emailCtrl.text.trim(),
      phone:     _phoneCtrl.text.trim(),
      password:  _passCtrl.text,
      degree:    _degree,
      faculty:   _faculty,
      direction: _direction,
      group:     _groupCtrl.text.trim(),
    );

    if (!ok && mounted) {
      setState(() => _errorMsg = app.error ?? 'Xatolik yuz berdi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app    = context.watch<AppProvider>();
    final isDark = app.isDark;

    final directions = (_degree == 'magistr'
        ? kMagistrDirections
        : (_faculty != null ? kFacultyDirections[_faculty!] ?? <String>[] : <String>[])).cast<String>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('Ro\'yhatdan o\'tish',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text('Talaba hisobi yaratish',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ),
              const SizedBox(height: 28),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Shaxsiy ma'lumotlar ──
                    const SectionTitle(label: "Shaxsiy ma'lumotlar", icon: Icons.person_outline),
                    AppTextField(
                      hint: 'To\'liq ism *',
                      controller: _nameCtrl,
                      prefix: const Icon(Icons.badge_outlined, size: 18),
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      hint: 'Email *',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefix: const Icon(Icons.email_outlined, size: 18),
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      hint: 'Telefon raqam *',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      prefix: const Icon(Icons.phone_outlined, size: 18),
                    ),

                    // ── Ta'lim ma'lumotlari ──
                    const SectionTitle(label: "Ta'lim ma'lumotlari", icon: Icons.school_outlined),

                    // Daraja
                    _DropdownField(
                      hint: 'Daraja *',
                      icon: Icons.workspace_premium_outlined,
                      value: _degree,
                      items: const ['bakalavr', 'magistr'],
                      onChanged: (v) => setState(() {
                        _degree = v!;
                        _faculty = null;
                        _direction = null;
                      }),
                    ),
                    const SizedBox(height: 10),

                    // Fakultet (faqat bakalavr)
                    if (_degree == 'bakalavr') ...[
                      _DropdownField(
                        hint: 'Fakultet',
                        icon: Icons.account_balance_outlined,
                        value: _faculty,
                        items: kFacultyNames,
                        onChanged: (v) => setState(() {
                          _faculty = v;
                          _direction = null;
                        }),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Yo'nalish
                    if (directions.isNotEmpty) ...[
                      _DropdownField(
                        hint: 'Yo\'nalish',
                        icon: Icons.route_outlined,
                        value: _direction,
                        items: directions,
                        onChanged: (v) => setState(() => _direction = v),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Guruh
                    AppTextField(
                      hint: 'Guruh (masalan: MTI-21)',
                      controller: _groupCtrl,
                      prefix: const Icon(Icons.group_outlined, size: 18),
                    ),

                    // ── Parol ──
                    const SectionTitle(label: 'Parol', icon: Icons.lock_outline),
                    _PasswordField(
                      hint: 'Parol * (kamida 6 ta belgi)',
                      controller: _passCtrl,
                      obscure: _obscure1,
                      onToggle: () => setState(() => _obscure1 = !_obscure1),
                    ),
                    const SizedBox(height: 10),
                    _PasswordField(
                      hint: 'Parolni tasdiqlang *',
                      controller: _pass2Ctrl,
                      obscure: _obscure2,
                      onToggle: () => setState(() => _obscure2 = !_obscure2),
                    ),

                    const SizedBox(height: 20),

                    // Xato xabari
                    if (_errorMsg != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMsg!,
                                style: const TextStyle(color: AppColors.red, fontSize: 12))),
                          ],
                        ),
                      ),
                    ],

                    AccentButton(
                      label: 'Ro\'yhatdan o\'tish',
                      icon: Icons.person_add_rounded,
                      loading: app.loading,
                      onTap: _register,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      text: 'Hisobingiz bormi? ',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      children: const [
                        TextSpan(
                          text: 'Kirish',
                          style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Yordamchi widgetlar ──

class _DropdownField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;

  const _DropdownField({
    required this.hint, required this.icon, required this.value,
    required this.items, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1923) : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Row(children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(hint, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1A2637) : Colors.white,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.hint, required this.controller,
    required this.obscure, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline, size: 18),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F1923) : const Color(0xFFF0F2F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}