import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';

class ChallengeData {
  final String title;
  final int daysLeft;
  final int daysTotal;
  final IconData icon;
  final int participants;

  const ChallengeData({
    required this.title,
    required this.daysLeft,
    required this.daysTotal,
    required this.icon,
    required this.participants,
  });
}

class ChallengeCard extends StatelessWidget {
  final ChallengeData challenge;

  const ChallengeCard({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (challenge.daysLeft / challenge.daysTotal);
    final urgent = challenge.daysLeft <= 3;
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;

    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: urgent
                ? AppColors.errorSoft.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10, offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(challenge.icon, size: 22, color: primary),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: urgent
                        ? AppColors.errorLight
                        : primaryLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${challenge.daysLeft}d',
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: urgent
                            ? AppColors.errorDark
                            : primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(challenge.title,
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.2),
                maxLines: 2),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.people_rounded, size: 11, color: AppColors.inkSoft),
                const SizedBox(width: 3),
                Text('${challenge.participants}',
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 10, color: AppColors.inkSoft)),
              ],
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: Colors.black.withValues(alpha: 0.07),
                valueColor: AlwaysStoppedAnimation<Color>(
                    urgent ? AppColors.errorSoft : primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
