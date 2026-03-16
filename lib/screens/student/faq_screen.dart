import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../constants.dart';
import '../../l10n.dart';

const _kDefaultFaq = [
  {
    'question': 'Ilovadan qanday foydalanaman?',
    'answer':
        'Ilovada siz turli kitoblarni ko\'rishingiz, o\'qishingiz va saqlab qo\'yishingiz mumkin. Shuningdek "Kitob bozori" bo\'limida talabalar o\'z kitoblarini sotish, ijaraga berish yoki bepul ulashishlari mumkin.',
  },
  {
    'question': 'Kitobni qanday yuklab olaman yoki o\'qiyman?',
    'answer':
        'Kitob sahifasiga kirib "O\'qish" yoki "Yuklab olish" tugmasini bosish orqali kitobni o\'qishingiz yoki qurilmangizga saqlashingiz mumkin.',
  },
  {
    'question': 'Kitob bozoriga qanday e\'lon joylayman?',
    'answer':
        'Pastki menyudagi "Bozor" bo\'limiga kiring va "E\'lon qo\'shish" tugmasini bosing. Kitob nomi, muallif, narx va tavsifni kiritib e\'lon joylashingiz mumkin.',
  },
  {
    'question': 'Kitobni ijaraga olish mumkinmi?',
    'answer':
        'Ha. Bozor bo\'limida "Ijara" filtrini tanlab ijaraga berilayotgan kitoblarni ko\'rishingiz mumkin.',
  },
  {
    'question': 'Sotuvchi bilan qanday bog\'lanaman?',
    'answer':
        'Kitob sahifasida sotuvchining telefon raqami yoki aloqa tugmasi orqali bevosita bog\'lanishingiz mumkin.',
  },
  {
    'question': 'Agar muammo bo\'lsa nima qilaman?',
    'answer':
        '"Qo\'llab-quvvatlash" bo\'limida berilgan email orqali biz bilan bog\'lanishingiz mumkin.',
  },
];

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app   = context.watch<AppProvider>();
    final s     = S.of(context);
    final items = app.faqItems.isNotEmpty ? app.faqItems : _kDefaultFaq;

    return Scaffold(
      appBar: AppBar(title: Text(s.faqTitle)),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.quiz_outlined,
                        size: 36, color: AppColors.blue),
                  ),
                  const SizedBox(height: 14),
                  Text(s.noFaqItems,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: items.length,
              itemBuilder: (_, i) => _FaqTile(
                question: items[i]['question'] ?? '',
                answer: items[i]['answer'] ?? '',
              ),
            ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _turn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _turn = Tween(begin: 0.0, end: 0.5).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _expanded
                  ? AppColors.accent.withOpacity(0.4)
                  : Theme.of(context).dividerColor.withOpacity(0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Q',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.question,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    RotationTransition(
                      turns: _turn,
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: _expanded
                              ? AppColors.accent
                              : Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              if (_expanded) ...[
                Divider(
                  height: 1,
                  color: AppColors.accent.withOpacity(0.2),
                  indent: 16,
                  endIndent: 16,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text('A',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.green)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.answer,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
