import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = S.of(context);
    const typeColors = {
      'new_books': AppColors.green,
      'info':      AppColors.blue,
      'reminder':  AppColors.accent,
      'survey':    AppColors.purple,
    };
    final typeLabels = {
      'new_books': s.typeNewBooks,
      'info':      s.typeInfo,
      'reminder':  s.typeReminder,
      'survey':    s.typeSurvey,
    };

    return Scaffold(
      appBar: AppBar(title: Text(s.announcements)),
      body: app.announcements.isEmpty
          ? Center(child: Text(s.noAnnouncementsYet, style: const TextStyle(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: app.announcements.length,
        itemBuilder: (_, i) {
          final a     = app.announcements[i];
          final color = typeColors[a.type] ?? AppColors.blue;
          final label = typeLabels[a.type] ?? s.typeInfo;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              borderColor: a.important ? AppColors.accent.withOpacity(0.5) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    StatusBadge(label: label, color: color),
                    if (a.important) ...[
                      const SizedBox(width: 6),
                      StatusBadge(label: s.important, color: AppColors.red),
                    ],
                    const Spacer(),
                    Text('${a.date.day}.${a.date.month}.${a.date.year}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ]),
                  const SizedBox(height: 10),
                  Text(a.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(a.content, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
                  const SizedBox(height: 8),
                  Text('✍️ ${a.author}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}