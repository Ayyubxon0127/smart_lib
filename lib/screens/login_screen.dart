import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'register_screen.dart';
import '../constants.dart';
import '../widgets/common_widgets.dart';
import '../l10n.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  bool _obscure       = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _errorMsg = null);
    final s = S.read(context);
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text; // parolni trim qilmaymiz

    if (email.isEmpty) {
      setState(() => _errorMsg = s.emptyEmail);
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMsg = s.invalidEmail);
      return;
    }
    if (pass.isEmpty) {
      setState(() => _errorMsg = s.emptyPassword);
      return;
    }
    if (pass.length < 6) {
      setState(() => _errorMsg = s.passwordTooShort);
      return;
    }

    final app = context.read<AppProvider>();
    final ok = await app.login(email, pass);
    if (!ok && mounted) {
      setState(() => _errorMsg = _friendlyError(app.error ?? '', s));
    }
  }

  String _friendlyError(String error, S s) {
    final e = error.toLowerCase();
    if (e.contains('invalid-credential') ||
        e.contains('wrong-password') ||
        e.contains('user-not-found') ||
        e.contains('invalid-email') && e.contains('password')) {
      return s.wrongCredentials;
    }
    if (e.contains('invalid-email')) return s.invalidEmail;
    if (e.contains('too-many-requests')) return s.tooManyRequests;
    if (e.contains('user-disabled')) return s.userDisabled;
    if (e.contains('network-request-failed') || e.contains('network')) return s.networkError;
    return s.wrongCredentials; // noma'lum xatoliklar uchun ham qulay xabar
  }

  @override
  Widget build(BuildContext context) {
    final app   = context.watch<AppProvider>();
    final s     = S.of(context);
    final isDark = app.isDark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.accentLight],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Colors.black, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(s.appTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              ),
              Center(
                child: Text(s.uniSystem,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ),
              const SizedBox(height: 48),

              // Form
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.signIn, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 20),
                    AppTextField(
                      hint: 'Email',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefix: const Icon(Icons.email_outlined, size: 18),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      hint: s.password,
                      controller: _passCtrl,
                      obscure: _obscure,
                      prefix: const Icon(Icons.lock_outline, size: 18),
                      suffix: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_errorMsg != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMsg!, style: const TextStyle(color: AppColors.red, fontSize: 12))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    AccentButton(label: s.signIn, icon: Icons.login_rounded, loading: app.loading, onTap: _login),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: RichText(
                    text: TextSpan(
                      text: s.noAccount,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      children: [
                        TextSpan(
                          text: s.registerLink,
                          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Theme / Lang toggles
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _langBtn(app, 'uz', "O'zbek"),
                  const SizedBox(width: 8),
                  _langBtn(app, 'ru', 'Русский'),
                  const SizedBox(width: 8),
                  _langBtn(app, 'en', 'English'),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: app.toggleDark,
                    child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: AppColors.accent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langBtn(AppProvider app, String code, String label) {
    final active = app.lang == code;
    return GestureDetector(
      onTap: () => app.setLang(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.accent : Colors.grey.shade400),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: active ? Colors.black : Colors.grey.shade400)),
      ),
    );
  }
}