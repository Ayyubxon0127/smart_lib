import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../constants.dart';
import '../../l10n.dart';

const _kDefaultFaq = [
  {
    'question': 'Coin va levellar qanday ishlaydi?',
    'answer':
        'Ilovada faolligingiz uchun coin (tanga) to\'playsiz:\n'
        '• Kitob qaytarganingizda: +20 coin\n'
        '• Kutubxona xonasida dars qilganingiz tasdiqlanganda: +5 coin\n\n'
        'Har 100 coin = 1 level. Masalan: 100 coin → Level 2, 200 coin → Level 3 va hokazo. '
        'Level va coinlaringizni Sozlamalar → Profilingizdan ko\'rishingiz mumkin.',
  },
  {
    'question': 'Qanday qilib yuqori levelga chiqaman?',
    'answer':
        'Ko\'proq kitob o\'qing va qaytaring — har bir qaytarish +20 coin beradi. '
        'Kutubxona xonalarida dars qiling — har bir tasdiqlangan sessiya +5 coin. '
        'Masalan, 5 ta kitob qaytarsangiz 100 coin (Level 2) bo\'ladi. '
        'Dars soatlaringiz ham real vaqt asosida hisoblanadi!',
  },
  {
    'question': 'Coin va levellarim qaerda ko\'rinadi?',
    'answer':
        'Sozlamalar bo\'limidagi profil kartochkasida coinlar, level va progress bar ko\'rinadi. '
        'Shuningdek o\'qilgan kitoblar soni, dars vaqti va kutubxonaga tashriflar soni ham real ma\'lumotlar asosida hisoblanadi.',
  },
  {
    'question': 'Ilovadan qanday foydalanaman?',
    'answer':
        'Ilovada siz turli kitoblarni ko\'rishingiz, bron qilishingiz va kutubxona xonalarini band qilishingiz mumkin. '
        '"Kitob bozori" bo\'limida talabalar o\'z kitoblarini sotish, ijaraga berish yoki bepul ulashishlari mumkin.',
  },
  {
    'question': 'Kitob bozoriga qanday e\'lon joylayman?',
    'answer':
        'Pastki menyudagi "Bozor" bo\'limiga kiring va "E\'lon qo\'shish" tugmasini bosing. '
        'Kitob nomi, muallif, narx va tavsifni kiritib e\'lon joylashingiz mumkin.',
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
