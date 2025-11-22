import 'package:flutter/material.dart';
import '../../core/themes/app_colors.dart';

class ProfileFieldTile extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  const ProfileFieldTile({
    super.key,
    required this.label,
    this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.lightGrey, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textLight, // Greyish for label
                fontSize: 14,
              ),
            ),
            Text(
              value ?? placeholder,
              style: TextStyle(
                // If value exists, use dark color. If placeholder (e.g. "add email"), use light grey
                color: value != null
                    ? AppColors.textDark
                    : AppColors.textLight.withOpacity(0.5),
                fontSize: 14,
                fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
