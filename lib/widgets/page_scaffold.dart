import 'package:flutter/material.dart';

class HrPage extends StatelessWidget {
  const HrPage({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 520;

    return SafeArea(
      top: false,
      child: Container(
        color: const Color(0xfffff9fb),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 24,
            compact ? 18 : 30,
            compact ? 14 : 24,
            compact ? 10 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: action == null || compact
                            ? double.infinity
                            : (width - 56).clamp(220, 520).toDouble(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: (compact
                                      ? Theme.of(context).textTheme.titleLarge
                                      : Theme.of(context)
                                          .textTheme
                                          .headlineSmall)
                                  ?.copyWith(
                                color: const Color(0xff252437),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: const Color(0xff8f8fa3),
                                      height: 1.25,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (action != null)
                        SizedBox(
                          width: compact ? double.infinity : null,
                          child: action!,
                        ),
                    ],
                  ),
                  SizedBox(height: compact ? 14 : 18),
                  Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: const Color(0xff999999)),
      ),
    );
  }
}

class ConfigBanner extends StatelessWidget {
  const ConfigBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xfffff3cd),
      borderRadius: BorderRadius.circular(10),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xffb86c00)),
            SizedBox(width: 8),
            Expanded(
              child: Text('ยังไม่ได้ตั้งค่า Supabase ข้อมูลจะแสดงเป็นค่าว่าง'),
            ),
          ],
        ),
      ),
    );
  }
}
