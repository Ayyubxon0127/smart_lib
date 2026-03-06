import 'package:flutter/material.dart';
import '../constants.dart';

// ── Accent Button ──
class AccentButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool loading;

  const AccentButton({super.key, required this.label, this.onTap, this.icon, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
      ),
    );
  }
}

// ── Card Container ──
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  const AppCard({super.key, required this.child, this.padding, this.onTap, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: child,
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: card);
    return card;
  }
}

// ── Status Badge ──
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

// ── Section Title ──
class SectionTitle extends StatelessWidget {
  final String label;
  final IconData? icon;

  const SectionTitle({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

// ── App Text Field ──
class AppTextField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscure;
  final int maxLines;
  final Widget? prefix;
  final Widget? suffix;

  const AppTextField({
    super.key, required this.hint, this.controller,
    this.keyboardType, this.obscure = false, this.maxLines = 1,
    this.prefix, this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: isDark ? const Color(0xFF0F1923) : const Color(0xFFF0F2F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
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

// ── Book Cover ──
class BookCover extends StatelessWidget {
  final String? imageUrl;
  final String emoji;
  final double width;
  final double height;

  const BookCover({super.key, this.imageUrl, required this.emoji, this.width = 44, this.height = 60});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl!,
          width: width, height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emojiBox(),
        ),
      );
    }
    return _emojiBox();
  }

  Widget _emojiBox() => Container(
    width: width, height: height,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.accent.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(emoji, style: TextStyle(fontSize: width * 0.6)),
  );
}
