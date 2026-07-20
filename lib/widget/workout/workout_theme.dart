import 'package:flutter/material.dart';

class WorkoutColors {
  // Shared light palette for the workout and nutrition sections.
  static const background = Color(0xFFF7F9FC);
  static const panel = Colors.white;
  static const panelSoft = Color(0xFFF2F6FA);
  static const border = Color(0xFFDDE5EE);
  static const green = Color(0xFF00C98B);
  static const greenDark = Color(0xFFD8F5EB);
  static const blue = Color(0xFF49A7FF);
  static const amber = Color(0xFFFFC400);
  static const text = Color(0xFF172033);
  static const muted = Color(0xFF6F7C8F);
}

Widget workoutPanel({
  required Widget child,
  EdgeInsets padding = const EdgeInsets.all(20),
}) {
  return Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: WorkoutColors.panel,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: WorkoutColors.border),
    ),
    child: child,
  );
}

Widget workoutSectionTitle(IconData icon, String title, {Widget? trailing}) {
  return Row(
    children: [
      Icon(icon, color: WorkoutColors.green, size: 18),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          color: WorkoutColors.text,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      const Spacer(),
      if (trailing != null) trailing,
    ],
  );
}

Widget workoutPrimaryButton({
  required String label,
  required VoidCallback? onPressed,
  IconData icon = Icons.arrow_forward_rounded,
}) {
  return SizedBox(
    width: double.infinity,
    height: 54,
    child: FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: WorkoutColors.green,
        disabledBackgroundColor: WorkoutColors.greenDark,
        foregroundColor: WorkoutColors.background,
        disabledForegroundColor: WorkoutColors.muted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

Widget workoutSecondaryButton({
  required String label,
  required VoidCallback? onPressed,
  IconData icon = Icons.arrow_back_rounded,
}) {
  return SizedBox(
    height: 50,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: WorkoutColors.muted,
        side: const BorderSide(color: WorkoutColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    ),
  );
}

Widget workoutMetric({
  required String label,
  required String value,
  Color color = WorkoutColors.text,
}) {
  return Expanded(
    child: Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: WorkoutColors.muted, fontSize: 10),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

Widget workoutMetricStrip(List<Widget> metrics) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: WorkoutColors.text.withValues(alpha: .9)),
    ),
    child: Row(
      children: [
        for (var index = 0; index < metrics.length; index++) ...[
          if (index > 0)
            Container(width: 1, height: 34, color: WorkoutColors.border),
          metrics[index],
        ],
      ],
    ),
  );
}

String workoutFormatDuration(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String workoutFormatTime(int seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final remainder = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$remainder';
}
